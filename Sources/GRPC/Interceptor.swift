/*
 * Copyright 2020, gRPC Authors All rights reserved.
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
import NIO
import NIOHPACK
import NIOHTTP2
import Logging

final class _Invoker {
  let eventLoop: EventLoop
  var logger: Logger

  init(eventLoop: EventLoop, logger: Logger) {
    self.eventLoop = eventLoop
    self.logger = logger
  }

  func invoke(with metadata: HPACKHeaders) {
    if self.eventLoop.inEventLoop {
      fatalError()
    } else {
      self.eventLoop.execute {
        fatalError()
      }
    }
  }

  func finish(status: GRPCStatus, trailers: HPACKHeaders) {
  }
}

protocol MetadataInterceptor {
  func intercept(metadata: HPACKHeaders, path: String, invoker: _Invoker)
  func receive(status: GRPCStatus, trailers: HPACKHeaders, invoker: _Invoker)
}

class FakeInterceptor: MetadataInterceptor {
  var cookie: String?
  var metadata: HPACKHeaders?

  func intercept(metadata: HPACKHeaders, path: String, invoker: _Invoker) {
    if let cookie = self.cookie {
      var metadata = metadata
      metadata.add(name: "some-cookie", value: cookie)
      invoker.invoke(with: metadata)
    } else {
      invoker.invoke(with: metadata)
    }
  }

  func receive(status: GRPCStatus, trailers: HPACKHeaders, invoker: _Invoker) {
    if status.code == .unauthenticated, trailers.first(name: "www-authenticate") != nil {
      self.doAuth(invoker: invoker).whenComplete { result in
        switch result {
        case .success:
          var metadata = self.metadata!
          metadata.add(name: "some-cookie", value: "some-value")
          invoker.invoke(with: metadata)

        case .failure:
          invoker.finish(status: .processingError, trailers: trailers)
        }
      }
    }
  }

  private func doAuth(invoker: _Invoker) -> EventLoopFuture<Void> {
    return invoker.eventLoop.makeSucceededFuture(())
  }
}

class BufferedInterceptor<Request, Response, Interceptor: MetadataInterceptor> {
  typealias RequestPart = _GRPCClientRequestPart<Request>

  private var requestPartBuffer = CircularBuffer<RequestPart>()
  private let interceptor: Interceptor
  private let invoker: _Invoker

  init(interceptor: Interceptor, invoker: _Invoker) {
    self.interceptor = interceptor
    self.invoker = invoker
  }

  func sendRequest(_ part: RequestPart, promise: EventLoopPromise<Void>?) {
    switch part {
    case .head(let head):
      self.interceptor.intercept(metadata: head.customMetadata, path: head.path, invoker: self.invoker)

    case .message, .end:
      self.requestPartBuffer.append(part)
    }
  }

  func invoke(with metadata: HPACKHeaders) {
    // create transport
    // invoke
    //
  }
}

class ClientInvoker<Request, Response> {
  var eventLoop: EventLoop

  init(eventLoop: EventLoop) {
    self.eventLoop = eventLoop
  }

  func writeMetadata(_ metadata: HPACKHeaders, promise: EventLoopPromise<Void>?) {}
  func writeRequest(_ request: Request, promise: EventLoopPromise<Void>?) {}
  func writeEnd(promise: EventLoopPromise<Void>?) {}
  func cancel(promise: EventLoopPromise<Void>?) {}

  func readMetadata(_ metadata: HPACKHeaders) {}
  func readResponse(_ response: Response) {}
  func readEnd(status: GRPCStatus, metadata: HPACKHeaders) {}
}

protocol ClientStream {
  associatedtype Request
  associatedtype Response

  func writeMetadata(_ metadata: HPACKHeaders, invoker: ClientInvoker<Request, Response>, promise: EventLoopPromise<Void>?)
  func writeRequest(_ request: Request, invoker: ClientInvoker<Request, Response>, promise: EventLoopPromise<Void>?)
  func writeEnd(promise: EventLoopPromise<Void>?, invoker: ClientInvoker<Request, Response>)
  func cancel(promise: EventLoopPromise<Void>?, invoker: ClientInvoker<Request, Response>)

  func readMetadata(_ metadata: HPACKHeaders, invoker: ClientInvoker<Request, Response>)
  func readResponse(_ response: Response, invoker: ClientInvoker<Request, Response>)
  func readEnd(status: GRPCStatus, metadata: HPACKHeaders, invoker: ClientInvoker<Request, Response>)
}

class LoggingClientStream<Request, Response>: ClientStream {
  func writeMetadata(_ metadata: HPACKHeaders, invoker: ClientInvoker<Request, Response>, promise: EventLoopPromise<Void>?) {
    invoker.writeMetadata(metadata, promise: promise)
  }

  func writeRequest(_ request: Request, invoker: ClientInvoker<Request, Response>, promise: EventLoopPromise<Void>?) {
    invoker.writeRequest(request, promise: promise)
  }

  func writeEnd(promise: EventLoopPromise<Void>?, invoker: ClientInvoker<Request, Response>) {
    invoker.writeEnd(promise: promise)
  }

  func cancel(promise: EventLoopPromise<Void>?, invoker: ClientInvoker<Request, Response>) {
    invoker.cancel(promise: promise)
  }

  func readMetadata(_ metadata: HPACKHeaders, invoker: ClientInvoker<Request, Response>) {
    invoker.readMetadata(metadata)
  }

  func readResponse(_ response: Response, invoker: ClientInvoker<Request, Response>) {
    invoker.readResponse(response)
  }

  func readEnd(status: GRPCStatus, metadata: HPACKHeaders, invoker: ClientInvoker<Request, Response>) {
    if status.code == .unauthenticated {
      // Do auth, then call write metadata.
      invoker.eventLoop.makeSucceededFuture(()).whenSuccess {
        invoker.writeMetadata([:], promise: nil)
      }
    }
    invoker.readEnd(status: status, metadata: metadata)
  }
}

protocol ClientStreamHandler {
  associatedtype Request
  associatedtype Response

  func invokeRPC(_ metadata: HPACKHeaders, promise: EventLoopPromise<Void>?)
  func sendRequest(_ request: Request, promise: EventLoopPromise<Void>?)
  func endRequestStream(promise: EventLoopPromise<Void>?)
  func cancel(promise: EventLoopPromise<Void>?)

  func receiveMetadata(_ metadata: HPACKHeaders)
  func receiveResponse(_ response: Response)
  func receiveEnd(status: GRPCStatus, metadata: HPACKHeaders)
}

class TransportProvidingHandler<Request, Response>: ClientStreamHandler {
  let transportFactory: () -> ChannelTransport<Request, Response>
  var transport: ChannelTransport<Request, Response>?

  init(transportFactory: @escaping () -> ChannelTransport<Request, Response>) {
    self.transportFactory = transportFactory
  }

  func invokeRPC(_ metadata: HPACKHeaders, promise: EventLoopPromise<Void>?) {
    if self.transport != nil {
      promise?.fail(GRPCStatus(code: .failedPrecondition, message: nil))
    } else {
      self.transport = self.transportFactory()

      // We'd need to pass in some RPC specific info on init to populate the request head.
      // Alternatively, this info could just be passed through the handlers instead of just the use
      // provided metadata.
      //
      // let requestHead = _GRPCRequestHead(..., customMetadata: metadata)
      // self.transport.sendRequest(.head(requestHead), promise: promise)
    }
  }

  func sendRequest(_ request: Request, promise: EventLoopPromise<Void>?) {
    if let transport = self.transport {
      transport.sendRequest(.message(.init(request, compressed: false)), promise: promise)
    } else {
      promise?.fail(GRPCStatus(code: .failedPrecondition, message: nil))
    }
  }

  func endRequestStream(promise: EventLoopPromise<Void>?) {
    if let transport = self.transport {
      transport.sendRequest(.end, promise: promise)
    } else {
      promise?.fail(GRPCStatus(code: .failedPrecondition, message: nil))
    }
  }

  func cancel(promise: EventLoopPromise<Void>?) {
    if let transport = self.transport {
      transport.cancel(promise: promise)
    } else {
      self.receiveEnd(status: GRPCStatus(code: .cancelled, message: nil), metadata: [:])
    }
  }

  func receiveMetadata(_ metadata: HPACKHeaders) {
    // Forward metadata
  }

  func receiveResponse(_ response: Response) {
    // Forward response
  }

  func receiveEnd(status: GRPCStatus, metadata: HPACKHeaders) {
    // Done with transport.
    self.transport = nil

    // Forward status/trailers
  }
}
