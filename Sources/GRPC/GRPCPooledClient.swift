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
    fatalError()
  }

  public func close() -> EventLoopFuture<Void> {
    fatalError()
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
  private var connections: [ObjectIdentifier: ConnectionAndState]
  private var connectionWaiters: CircularBuffer<Waiter>
  private var nextConnectionThreshold: Int
  private let queue: DispatchQueue
  private let logger: Logger

  init(
    group: EventLoopGroup,
    queue: DispatchQueue,
    maximumConnections: Int,
    connectionBringUpThreshold: Int  = 10,
    logger: Logger
  ) {
    precondition(maximumConnections > 0)

    logger.debug("Creating connection pool", metadata: ["pool_size": "\(maximumConnections)"])

    self.nextConnectionThreshold = connectionBringUpThreshold
    self.queue = queue
    self.logger = logger
    self.connectionWaiters = CircularBuffer(initialCapacity: 16)

    self.connections = [:]
    self.connections.reserveCapacity(maximumConnections)
    for _ in 0 ..< maximumConnections {
      self.addManagerToPool(Self.makeConnectionManager(group: group, queue: queue, logger: logger))
    }
  }

  private static func makeConnectionManager(group: EventLoopGroup, queue: DispatchQueue, logger: Logger) -> ConnectionManager {
    // TODO: proper configuration.
    let configuration = ClientConnection.Configuration(
      target: .hostAndPort("", 0),
      eventLoopGroup: group.next(),
      connectivityStateDelegateQueue: queue,
      callStartBehavior: .waitsForConnectivity,
      backgroundActivityLogger: logger
    )

    return ConnectionManager(
      configuration: configuration,
      logger: logger
    )
  }

  private func addManagerToPool(_ manager: ConnectionManager) {
    let connectionAndState = ConnectionAndState(connectionManager: manager)
    // TODO: is there a ref-cycle here?
    manager.monitor.delegate = ConnectivityMonitor(pool: self, connectionID: connectionAndState.id)
    self.connections[connectionAndState.id] = connectionAndState
  }

  private func getUsableConnections() -> [ConnectionAndState] {
    return self.connections.values.filter { $0.availableLeases > 0 }
  }

  internal func getMultiplexer(eventLoop: EventLoop) -> EventLoopFuture<HTTP2StreamMultiplexer> {
    let promise = eventLoop.makePromise(of: ConnectionDetails.self)

    self.queue.async {
      self.getMultiplexer(promise: promise)
    }

    return promise.futureResult.flatMap { details in
      return details.eventLoop.makeSucceededFuture(details.multiplexer)
    }
  }

  private func getMultiplexer(promise: EventLoopPromise<ConnectionDetails>) {
    self.queue.assertOnQueue()

    let requestAnotherConnection: Bool
    let connection = self.getUsableConnections().max(by: { $0.availableLeases < $1.availableLeases })

    if let connection = connection {
      // Of all the usable connections, this one has the fewest active RPCs, but it's high enough
      // that we should spin up an idle connection (if there is an idle one).
      requestAnotherConnection = connection.leases >= self.nextConnectionThreshold

      // We know there are available leases, so the force unwrap is fine.
      let connectionDetails = self.connections[connection.id]!.leaseStream()!
      promise.succeed(connectionDetails)
    } else {
      requestAnotherConnection = true
      self.makeWaiter(promise: promise)
    }

    if requestAnotherConnection {
      self.requestConnection()
    }
  }

  private func makeWaiter(promise: EventLoopPromise<ConnectionDetails>) {
    var waiter = Waiter(multiplexerPromise: promise)

    waiter.scheduleDeadline(.now() + .seconds(10), onEventLoop: promise.futureResult.eventLoop) {
      self.queue.async {
        // TODO: use a better error.
        waiter.fail(GRPCError.AlreadyComplete())

        if let index = self.connectionWaiters.firstIndex(where: { $0.id == waiter.id }) {
          self.connectionWaiters.remove(at: index)
        }
      }
    }

    self.connectionWaiters.append(waiter)
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
      self.connections[connectionID]?.connected(multiplexer: multiplexer)
    }

    promise.futureResult.whenFailureBlocking(onto: self.queue) { error in
      // TODO: failed to get a multiplexer, bugger.
      fatalError()
    }

    // Start connecting.
    // TODO: we need to ensure that the right call start behaviour is used.
    promise.completeWith(connection.connectionManager.getHTTP2Multiplexer())
  }

  private func updateConnectionState(
    _ state: ConnectivityState,
    forConnection connectionID: ObjectIdentifier
  ) {
    self.queue.assertOnQueue()

    if let action = self.connections[connectionID]?.connectivityStateChanged(to: state) {
      switch action {
      case .askForNewMultiplexer:
        self.startConnecting(connectionID: connectionID)

      case .checkWaiters:
        self.serviceWaiters()

      case .removeFromConnectionList:
        self.connections.removeValue(forKey: connectionID)
      }
    }
  }

  private func connectionIsQuiescing(connectionID: ObjectIdentifier) {
    self.queue.assertOnQueue()

    // The connection is quiescing, remove it and replace it with a new one on that same event
    // loop. We don't need to shut down the connection, it will do so once fully quiesced.
    if let connection = self.connections.removeValue(forKey: connectionID) {
      let connectionManager = Self.makeConnectionManager(
        group: connection.connectionManager.eventLoop,
        queue: self.queue,
        logger: self.logger
      )

      self.addManagerToPool(connectionManager)
    }
  }

  private func serviceWaiters() {
    if self.connectionWaiters.isEmpty {
      return
    }

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

struct Waiter {
  private var promise: EventLoopPromise<ConnectionDetails>
  private var timeoutTask: Scheduled<Void>?

  var multiplexer: EventLoopFuture<ConnectionDetails> {
    // TODO: this is *not* necessarily on the event loop of the multiplexer.
    return self.promise.futureResult
  }

  var id: ObjectIdentifier {
    return ObjectIdentifier(self.multiplexer)
  }

  init(multiplexerPromise: EventLoopPromise<ConnectionDetails>) {
    self.promise = multiplexerPromise
  }

  mutating func scheduleDeadline(
    _ deadline: NIODeadline,
    onEventLoop eventLoop: EventLoop,
    onTimeout: @escaping () -> Void
  ) {
    assert(self.timeoutTask == nil)
    self.timeoutTask = eventLoop.scheduleTask(deadline: deadline, onTimeout)
  }

  func succeed(_ multiplexer: ConnectionDetails) {
    self.timeoutTask?.cancel()
    self.promise.succeed(multiplexer)
  }

  func fail(_ error: Error) {
    self.timeoutTask?.cancel()
    self.promise.fail(error)
  }
}

struct ConnectionAndState {
  /// A manager for the connection we're leasing.
  internal let connectionManager: ConnectionManager

  /// The maximum number of times we can lease out the multiplexer from our managed connection.
  /// Assuming each lease corresponds to a single HTTP/2 stream then this should match the value
  /// of `SETTINGS_MAX_CONCURRENT_STREAMS`.
  internal private(set) var maximumLeases: Int

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

  mutating func leaseStream() -> ConnectionDetails? {
    return self.leaseStreams(1)
  }

  mutating func leaseStreams(_ extraLeases: Int) -> ConnectionDetails? {
    switch self.state {
    case .ready(let multiplexer, var leases):
      leases += extraLeases
      self.state = .ready(multiplexer, leases)
      assert(leases <= self.maximumLeases)
      return ConnectionDetails(multiplexer: multiplexer, eventLoop: self.connectionManager.eventLoop)

    case .idle, .connectingOrBackingOff:
      preconditionFailure()
    }
  }

  mutating func returnStream() {
    switch self.state {
    case .ready(let multiplexer, var leases):
      leases -= 1
      self.state = .ready(multiplexer, leases)
      assert(leases >= 0)

    case .idle, .connectingOrBackingOff:
      preconditionFailure()
    }
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
