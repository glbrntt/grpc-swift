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
import EchoModel
import EchoImplementation
import GRPC
import NIO
import XCTest

class GRPCPooledClientTests: GRPCTestCase {
  private var server: Server!
  private var client: GRPCPooledClient!
  private var group: EventLoopGroup!

  override func setUp() {
    super.setUp()

    self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    self.server = try! Server.insecure(group: self.group)
      .withServiceProviders([EchoProvider()])
//      .withLogger(self.serverLogger)
      .bind(host: "127.0.0.1", port: 0)
      .wait()

    let configuration = GRPCPooledClient.Configuration(
      group: self.group,
      maximumPoolSize: 4,
      host: "127.0.0.1",
      port: self.server.channel.localAddress!.port!,
      queue: DispatchQueue(label: "io.grpc.pooled-client"),
      logger: self.clientLogger
    )

    self.client = GRPCPooledClient(configuration: configuration)
  }

  override func tearDown() {
    XCTAssertNoThrow(try self.server.close().wait())
    XCTAssertNoThrow(try self.client.close().wait())
    XCTAssertNoThrow(try self.group.syncShutdownGracefully())
    super.tearDown()
  }

  func testFoo() throws {
    let echo = Echo_EchoClient(channel: self.client)

    let group = DispatchGroup()

    for index in 0 ..< 100 {
      group.enter()
      let get = echo.get(.with { $0.text = "\(index)" })
      get.response.whenSuccess {
        print("Response: \($0.text)")
        group.leave()
      }
    }

    group.wait()
  }
}
