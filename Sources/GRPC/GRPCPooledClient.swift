/*
 * Copyright 2021, gRPC Authors All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import Dispatch
import NIO
import NIOHTTP2
import Logging
import SwiftProtobuf

public final class GRPCPooledClient: GRPCChannel {
  private let group: EventLoopGroup
  private let pool: ConnectionPool

  private let authority: String
  private let scheme: String

  public init(configuration: Configuration) {
    self.group = configuration.group
    self.pool = ConnectionPool(
      host: configuration.host,
      port: configuration.port,
      group: configuration.group,
      queue: configuration.queue,
      maximumConnections: configuration.maximumPoolSize,
      logger: configuration.logger
    )
    self.authority = configuration.host
    self.scheme = "http"
  }

  public func makeCall<Request: Message, Response: Message>(
    path: String,
    type: GRPCCallType,
    callOptions: CallOptions,
    interceptors: [ClientInterceptor<Request, Response>]
  ) -> Call<Request, Response> {
    let eventLoop = callOptions.eventLoopPreference.exact ?? self.group.next()
    let multiplexer = self.pool.getMultiplexer(eventLoop: eventLoop)
    let call = Call(
      path: path,
      type: type,
      eventLoop: eventLoop,
      options: callOptions,
      interceptors: interceptors,
      transportFactory: .http2(
        multiplexer: multiplexer,
        authority: self.authority,
        scheme: self.scheme,
        errorDelegate: nil
      )
    )

    return call
  }

  public func makeCall<Request: GRPCPayload, Response: GRPCPayload>(
    path: String,
    type: GRPCCallType,
    callOptions: CallOptions,
    interceptors: [ClientInterceptor<Request, Response>]
  ) -> Call<Request, Response> {
    let eventLoop = callOptions.eventLoopPreference.exact ?? self.group.next()
    let multiplexer = self.pool.getMultiplexer(eventLoop: eventLoop)
    let call = Call(
      path: path,
      type: type,
      eventLoop: eventLoop,
      options: callOptions,
      interceptors: interceptors,
      transportFactory: .http2(
        multiplexer: multiplexer,
        authority: self.authority,
        scheme: self.scheme,
        errorDelegate: nil
      )
    )

    return call
  }

  public func close() -> EventLoopFuture<Void> {
    let eventLoop = self.group.next()
    let promise = eventLoop.makePromise(of: Void.self)
    self.close(promise: promise)
    return promise.futureResult
  }

  public func close(promise: EventLoopPromise<Void>) {
    self.pool.shutdown(promise: promise)
  }
}

extension GRPCPooledClient {
  public struct Configuration {
    public var group: EventLoopGroup
    public var maximumPoolSize: Int
    public var host: String
    public var port: Int
    public var queue: DispatchQueue
    public var logger: Logger

    public init(
      group: EventLoopGroup,
      maximumPoolSize: Int,
      host: String,
      port: Int,
      queue: DispatchQueue,
      logger: Logger
    ) {
      self.group = group
      self.maximumPoolSize = maximumPoolSize
      self.host = host
      self.port = port
      self.queue = queue
      self.logger = logger
    }
  }
}

final class ConnectionPool {
  private var connections: [ObjectIdentifier: MultiplexerManager]
  private var connectionWaiters: CircularBuffer<Waiter>
  private var nextConnectionThreshold: Int
  private var state: State = .active
  private let queue: DispatchQueue
  private var logger: Logger
  private let channelProvider: DefaultChannelProvider

  private enum State {
    case active
    case shuttingDown(EventLoopFuture<Void>)
    case shutdown
  }

  init(
    host: String,
    port: Int,
    group: EventLoopGroup,
    queue: DispatchQueue,
    maximumConnections: Int,
    connectionBringUpThreshold: Int = 10,
    logger: Logger
  ) {
    precondition(maximumConnections > 0)
    self.nextConnectionThreshold = connectionBringUpThreshold
    self.queue = queue
    self.logger = logger
    self.channelProvider = DefaultChannelProvider(
      connectionTarget: .hostAndPort(host, port),
      connectionKeepalive: ClientConnectionKeepalive(),
      connectionIdleTimeout: .minutes(5),
      tlsConfiguration: nil,
      tlsHostnameOverride: nil,
      tlsCustomVerificationCallback: nil,
      httpTargetWindowSize: 65535,
      errorDelegate: nil,
      debugChannelInitializer: nil
    )

    self.connectionWaiters = CircularBuffer(initialCapacity: 16)
    self.connections = [:]
    self.connections.reserveCapacity(maximumConnections)

    self.logger[metadataKey: "pool_id"] = "\(ObjectIdentifier(self))"
    self.logger.debug("Making connection pool", metadata: ["pool_size": "\(maximumConnections)"])

    // Fill the pool with managed connections (they'll be idle).
    for _ in 0 ..< maximumConnections {
      self.addNewMultiplexerManagerToPool(on: group.next())
    }
  }

  internal func getMultiplexer(eventLoop: EventLoop) -> EventLoopFuture<HTTP2StreamMultiplexer> {
    let promise = eventLoop.makePromise(of: HTTP2StreamMultiplexer.self)

    self.queue.async {
      self.getMultiplexer(promise: promise)
    }

    return promise.futureResult
  }

  internal func shutdown(promise: EventLoopPromise<Void>) {
    let eventLoop = promise.futureResult.eventLoop

    self.queue.async {
      switch self.state {
      case .active:
        self.state = .shuttingDown(promise.futureResult)

        promise.futureResult.whenComplete { _ in
          self.shutdownCompleted()
        }

        let shutdownFutures = self.connections.values.map {
          $0.connectionManager.shutdown()
        }

        // TODO: use the 'promise' accepting version when it's released to save an allocation.
        EventLoopFuture.andAllSucceed(shutdownFutures, on: eventLoop).cascade(to: promise)

      case let .shuttingDown(future):
        promise.completeWith(future)

      case .shutdown:
        // TODO: or fail?
        promise.succeed(())
      }
    }
  }

  private func shutdownCompleted() {
    self.queue.async {
      self.state = .shutdown
    }
  }

  private func addNewMultiplexerManagerToPool(on eventLoop: EventLoop) {
    let connectionManager = ConnectionManager(
      eventLoop: eventLoop,
      channelProvider: self.channelProvider,
      callStartBehavior: .waitsForConnectivity,
      connectionBackoff: ConnectionBackoff(),
      // This is set just below (we need the object identifier).
      connectivityStateDelegate: nil,
      connectivityStateDelegateQueue: self.queue,
      logger: self.logger
    )

    let muxManager = MultiplexerManager(connectionManager: connectionManager)

    // When do we break this reference cycle?
    muxManager.connectionManager.monitor.delegate = ConnectivityMonitor(
      forMultiplexerManager: muxManager,
      inPool: self
    )

    // This isn't part of the connectivity delegate API and we don't really want it to be. This is
    // just a convenient place to put it as it's executed on the right `DispatchQueue`.
    muxManager.connectionManager.monitor.httpNotifications(
      onStreamClosed: { self.returnLease(forConnection: muxManager.id) },
      onMaxConcurrentStreamChanged: { self.updateMaximumLeases($0, forConnection: muxManager.id) }
    )

    self.logger.trace("Adding connection to pool", metadata: [
      "connection_id": "\(muxManager.id)"
    ])

    self.connections[muxManager.id] = muxManager
  }

  private func makeConnectivityStateDelegate(
    forConnectionIdentifiedBy id: ObjectIdentifier,
    inPool pool: ConnectionPool
  ) -> ConnectivityStateDelegate {
    return ConnectivityMonitor(pool: self, connectionID: id)
  }

  private func getUsableConnections() -> [MultiplexerManager] {
    return self.connections.values.filter {
      $0.availableLeases > 0
    }
  }

  private func getLeastUsedUsableConnection() -> MultiplexerManager? {
    return self.getUsableConnections().min { lhs, rhs in
      lhs.availableLeases < rhs.availableLeases
    }
  }

  private func getMultiplexer(promise: EventLoopPromise<HTTP2StreamMultiplexer>) {
    self.queue.assertOnQueue()

    let requestAnotherConnection: Bool
    let connection = self.getUsableConnections().max(by: { $0.availableLeases < $1.availableLeases })

    if let connection = connection {
      // Of all the usable connections, this one has the fewest active RPCs, but it's high enough
      // that we should spin up an idle connection (if there is an idle one).
      requestAnotherConnection = connection.leases >= self.nextConnectionThreshold

      // We know there are available leases, so the force unwrap is fine.
      let connectionDetails = self.connections[connection.id]!.leaseStream()!

      self.logger.trace("Leasing stream from existing connection", metadata: [
        "connection_id": "\(connection.id)"
      ])
      promise.succeed(connectionDetails)
    } else {
      requestAnotherConnection = true
      self.makeWaiter(promise: promise)
    }

    if requestAnotherConnection {
      self.requestConnection()
    }
  }

  private func makeWaiter(promise: EventLoopPromise<HTTP2StreamMultiplexer>) {
    var waiter = Waiter(multiplexerPromise: promise)

    waiter.scheduleDeadline(.now() + .seconds(10), onQueue: self.queue) {
      // TODO: use a better error.
      waiter.fail(GRPCError.AlreadyComplete())

      if let index = self.connectionWaiters.firstIndex(where: { $0.id == waiter.id }) {
        self.connectionWaiters.remove(at: index)
      }
    }

    self.connectionWaiters.append(waiter)
    self.logger.trace("Enqueued connection waiter", metadata: [
      "num_waiters": "\(self.connectionWaiters.count)"
    ])
  }

  private func requestConnection() {
    if let connectionID = self.connections.first(where: { $0.value.isIdle })?.key {
      self.startConnecting(connectionID: connectionID)
    }
  }

  private func startConnecting(connectionID: ObjectIdentifier) {
    self.queue.assertOnQueue()

    guard let connection = self.connections[connectionID] else {
      return
    }

    // Asking for a multiplexer will start the connection process.
    let promise = connection.connectionManager.eventLoop.makePromise(of: HTTP2StreamMultiplexer.self)
    self.connections[connectionID]?.willStartConnecting(multiplexer: promise.futureResult)

    promise.futureResult.whenSuccessBlocking(onto: self.queue) { multiplexer in
      self.logger.trace("connection ready", metadata: ["connection_id": "\(connectionID)"])
      self.connections[connectionID]?.connected(multiplexer: multiplexer)
      self.tryServicingManyWaiters()
    }

    // Start connecting.
    self.logger.trace("starting connection", metadata: ["connection_id": "\(connectionID)"])
    promise.completeWith(connection.connectionManager.getHTTP2Multiplexer())
  }

  private func updateConnectionState(
    _ state: ConnectivityState,
    forConnection connectionID: ObjectIdentifier
  ) {
    self.queue.assertOnQueue()
    self.logger.trace("Connectivity state changed to \(state)", metadata: [
      "connection_id": "\(connectionID)"
    ])

    if let action = self.connections[connectionID]?.connectivityStateChanged(to: state) {
      switch action {
      case .askForNewMultiplexer:
        self.startConnecting(connectionID: connectionID)

      case .checkWaiters:
        self.tryServicingManyWaiters()

      case .removeFromConnectionList:
        self.logger.trace("Removing connection from pool", metadata: [
          "connection_id": "\(connectionID)"
        ])
        self.removeManagerFromPool(identifiedBy: connectionID)
      }
    }
  }

  private func returnLease(forConnection connectionID: ObjectIdentifier) {
    self.queue.assertOnQueue()
    self.logger.trace("Returning lease", metadata: [
      "connection_id": "\(connectionID)"
    ])
    self.connections[connectionID]?.returnStream()
    self.tryServivingOneWaiter()
  }

  private func updateMaximumLeases(_ limit: Int, forConnection connectionID: ObjectIdentifier) {
    self.queue.assertOnQueue()

    if let oldLimit = self.connections[connectionID]?.updateMaximumLeases(limit), limit > oldLimit {
      // Only try to service waiters if the limit increased.
      self.tryServicingManyWaiters()
    }
  }

  @discardableResult
  private func removeManagerFromPool(identifiedBy id: ObjectIdentifier) -> MultiplexerManager? {
    guard let manager = self.connections.removeValue(forKey: id) else {
      return nil
    }

    // The monitor has references to this pool, we'll break those cycles now.
    manager.connectionManager.monitor.delegate = nil
    manager.connectionManager.monitor.httpNotifications(
      onStreamClosed: nil,
      onMaxConcurrentStreamChanged: nil
    )

    return manager
  }

  private func connectionIsQuiescing(connectionID: ObjectIdentifier) {
    self.queue.assertOnQueue()

    // The connection is quiescing, remove it and replace it with a new one on that same event
    // loop. We don't need to shut down the connection, it will do so once fully quiesced.
    if let connection = self.removeManagerFromPool(identifiedBy: connectionID) {
      self.addNewMultiplexerManagerToPool(on: connection.connectionManager.eventLoop)
    }
  }

  private func tryServivingOneWaiter() {
    guard self.connectionWaiters.count > 0,
          var usableConnection = self.getLeastUsedUsableConnection() else {
      return
    }

    self.logger.trace("Servicing at most one connection waiter", metadata: [
      "num_waiters": "\(self.connectionWaiters.count)"
    ])


    // The connection has an available stream and we're only leasing one, so force unwrap is okay.
    let multiplexer = usableConnection.leaseStream()!
    self.connections.updateValue(usableConnection, forKey: usableConnection.id)

    let waiter = self.connectionWaiters.removeFirst()

    self.logger.trace("Leasing stream", metadata: [
      "connection_id": "\(usableConnection.id)",
      "new_leases": "\(1)",
      "available_leases": "\(usableConnection.availableLeases)",
      "num_waiters": "\(self.connectionWaiters.count)"
    ])

    waiter.succeed(multiplexer)
  }

  private func tryServicingManyWaiters() {
    guard self.connectionWaiters.count > 0 else {
      return
    }

    self.logger.trace("Servicing connection waiters", metadata: [
      "num_waiters": "\(self.connectionWaiters.count)"
    ])

    // Sort connections by the number of streams available for lease.
    var usableConnections = self.getUsableConnections()
    usableConnections.sort(by: { $0.availableLeases < $1.availableLeases })

    // TODO: it'd be better if we could distribute leases evenly from connections rather than
    // piling on a single connection.
    while var connection = usableConnections.popLast(), !self.connectionWaiters.isEmpty {
      let leases = min(connection.availableLeases, self.connectionWaiters.count)
      // The connection has available streams and we're not leasing any more than that number so
      // force unwrapping is okay.
      let multiplexer = connection.leaseStreams(leases)!
      self.connections.updateValue(connection, forKey: connection.id)

      self.logger.trace("Leasing streams", metadata: [
        "connection_id": "\(connection.id)",
        "new_leases": "\(leases)",
        "available_leases": "\(connection.availableLeases)",
        "num_waiters": "\(self.connectionWaiters.count - leases)"
      ])

      for _ in 0 ..< leases {
        let waiter = self.connectionWaiters.removeFirst()
        waiter.succeed(multiplexer)
      }
    }
  }
}

extension ConnectionPool {
  final class ConnectivityMonitor: ConnectivityStateDelegate {
    private let connectionID: ObjectIdentifier
    private let pool: ConnectionPool

    init(forMultiplexerManager manager: MultiplexerManager, inPool pool: ConnectionPool) {
      self.connectionID = manager.id
      self.pool = pool
    }

    init(pool: ConnectionPool, connectionID: ObjectIdentifier) {
      self.connectionID = connectionID
      self.pool = pool
    }

    func connectivityStateDidChange(
      from oldState: ConnectivityState,
      to newState: ConnectivityState
    ) {
      self.pool.updateConnectionState(newState, forConnection: self.connectionID)
    }

    func connectionStartedQuiescing() {
      self.pool.connectionIsQuiescing(connectionID: self.connectionID)
    }
  }
}

extension ConnectionPool {
  struct Waiter {
    private var multiplexerPromise: EventLoopPromise<HTTP2StreamMultiplexer>
    private var timeoutTask: Optional<DispatchWorkItem>

    var multiplexer: EventLoopFuture<HTTP2StreamMultiplexer> {
      return self.multiplexerPromise.futureResult
    }

    var id: ObjectIdentifier {
      return ObjectIdentifier(self.multiplexer)
    }

    init(multiplexerPromise: EventLoopPromise<HTTP2StreamMultiplexer>) {
      self.multiplexerPromise = multiplexerPromise
      self.timeoutTask = nil
    }

    mutating func scheduleDeadline(
      _ deadline: DispatchTime,
      onQueue queue: DispatchQueue,
      onTimeout execute: @escaping () -> Void
    ) {
      assert(self.timeoutTask == nil)

      let workItem = DispatchWorkItem(block: execute)
      self.timeoutTask = workItem
      queue.asyncAfter(deadline: deadline, execute: workItem)
    }

    func succeed(_ multiplexer: HTTP2StreamMultiplexer) {
      self.timeoutTask?.cancel()
      self.multiplexerPromise.succeed(multiplexer)
    }

    func fail(_ error: Error) {
      self.timeoutTask?.cancel()
      self.multiplexerPromise.fail(error)
    }
  }
}

struct MultiplexerManager {
  /// A manager for the multiplexer we're leasing streams from.
  internal let connectionManager: ConnectionManager

  /// The maximum number of times we can lease out the multiplexer from our managed connection.
  /// Assuming each lease corresponds to a single HTTP/2 stream then this should match the value
  /// of `SETTINGS_MAX_CONCURRENT_STREAMS`.
  private var maximumLeases: Int

  /// Connection state.
  private var state: State

  private enum State {
    /// No connection has been asked for, there are no leases.
    case idle

    /// A connection attempt is underway or we may be waiting to attempt to connect again.
    case connectingOrBackingOff(EventLoopFuture<HTTP2StreamMultiplexer>)

    /// We have an active connection which may have been leased our a number of times.
    case ready(HTTP2StreamMultiplexer, Int)

    /// Whether the state is `idle`.
    var isIdle: Bool {
      switch self {
      case .idle:
        return true
      case .connectingOrBackingOff, .ready:
        return false
      }
    }
  }

  init(connectionManager: ConnectionManager, maximumLeases: Int = 100) {
    self.connectionManager = connectionManager
    self.state = .idle
    self.maximumLeases = maximumLeases
  }

  /// An identifier for the connection manager.
  var id: ObjectIdentifier {
    return ObjectIdentifier(self.connectionManager)
  }

  /// Indicates whether the managed connection is idle.
  var isIdle: Bool {
    return self.state.isIdle
  }

  /// The number of existing leases.
  var leases: Int {
    switch self.state {
    case let .ready(_, leases):
      return leases
    case .idle, .connectingOrBackingOff:
      return 0
    }
  }

  /// The number of leases available on this connection.
  var availableLeases: Int {
    switch self.state {
    case let .ready(_, existingLeases):
      return self.maximumLeases - existingLeases
    case .idle, .connectingOrBackingOff:
      return 0
    }
  }

  /// The multiplexer associated with this connection if the connection is ready, `nil` otherwise.
  /// Callers are responsible for checking whether leases are available before vending out the
  /// multiplexer.
  var multiplexer: HTTP2StreamMultiplexer? {
    switch self.state {
    case let .ready(multiplexer, _):
      return multiplexer
    case .idle, .connectingOrBackingOff:
      return nil
    }
  }

  // MARK: - Lease Management

  mutating func leaseStream() -> HTTP2StreamMultiplexer? {
    return self.leaseStreams(1)
  }

  mutating func leaseStreams(_ extraLeases: Int) -> HTTP2StreamMultiplexer? {
    switch self.state {
    case .ready(let multiplexer, var leases):
      leases += extraLeases
      self.state = .ready(multiplexer, leases)
      assert(leases <= self.maximumLeases)
      return multiplexer

    case .idle, .connectingOrBackingOff:
      preconditionFailure()
    }
  }

  mutating func returnStream() {
    switch self.state {
    case .ready(let multiplexer, var leases):
      leases -= 1
      self.state = .ready(multiplexer, leases)

    case .idle, .connectingOrBackingOff:
      preconditionFailure()
    }
  }

  mutating func updateMaximumLeases(_ newValue: Int) -> Int {
    let oldValue = self.maximumLeases
    self.maximumLeases = newValue
    return oldValue
  }

  mutating func willStartConnecting(multiplexer: EventLoopFuture<HTTP2StreamMultiplexer>) {
    switch self.state {
    case .idle, .ready:
      // We can start connecting from the 'ready' state again if the connection was dropped.
      self.state = .connectingOrBackingOff(multiplexer)

    case .connectingOrBackingOff:
      preconditionFailure()
    }
  }

  mutating func connected(multiplexer: HTTP2StreamMultiplexer) {
    switch self.state {
    case .connectingOrBackingOff:
      self.state = .ready(multiplexer, 0)

    case .idle, .ready:
      preconditionFailure()
    }
  }

  mutating func connectivityStateChanged(to state: ConnectivityState) -> StateChangeAction? {
    // We only care about a few transitions as we mostly rely on our own state transitions. Namely,
    // we care we notices a change from ready to transient failure (as we need to update our own
    // state and drop any leases).

    // We care about shutting down as well.
    switch state {
    case .idle:
      self.state = .idle
      return nil

    case .transientFailure:
      switch self.state {
      case .ready:
        return .askForNewMultiplexer

      case .idle, .connectingOrBackingOff:
        return nil
      }

    case .shutdown:
      return .removeFromConnectionList

    case .connecting, .ready:
      // We aren't interested in connecting transitions.
      return nil
    }
  }

  enum StateChangeAction {
    case removeFromConnectionList
    case askForNewMultiplexer
    case checkWaiters
  }
}

struct ConnectionDetails {
  /// An HTTP/2 stream multiplexer.
  var multiplexer: HTTP2StreamMultiplexer

  /// The event loop of the `Channel` using the multiplexer.
  var eventLoop: EventLoop
}

extension DispatchQueue {
  func assertOnQueue() {
    debugOnly {
      self.preconditionOnQueue()
    }
  }

  func preconditionOnQueue() {
    if #available(OSX 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *) {
      dispatchPrecondition(condition: .onQueue(self))
    }
  }
}

@inlinable
internal func debugOnly(_ body: () -> Void) {
    assert({ body(); return true }())
}
