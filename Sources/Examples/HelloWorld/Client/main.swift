/*
 * Copyright 2019, gRPC Authors All rights reserved.
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
import ArgumentParser
import Dispatch
import GRPC
import HelloWorldModel
import Logging
import NIO
import NIOConcurrencyHelpers

func greet(name: String?, client greeter: Helloworld_GreeterClient) {
  // Form the request with the name, if one was provided.
  let request = Helloworld_HelloRequest.with {
    $0.name = name ?? ""
  }

  // Make the RPC call to the server.
  let sayHello = greeter.sayHello(request)

  // wait() on the response to stop the program from exiting before the response is received.
  do {
    let response = try sayHello.response.wait()
    print("Greeter received: \(response.message)")
  } catch {
    print("Greeter failed: \(error)")
  }
}

let queue = DispatchQueue(label: "runner", qos: .userInitiated)
var count = 0
var running = true

struct HelloWorld: ParsableCommand {
  @Option(help: "The port to connect to")
  var port: Int = 1234

  @Option(help: "The number of cores to use")
  var cores: Int = System.coreCount / 2

  @Option(help: "Target concurrent RPCs per core")
  var rpcsPerCore: Int = 50

  @Option(help: "Duration (in seconds)")
  var duration: Int = 30

  @Flag(help: "Use the connection pool")
  var useConnectionPool = false

  @Argument(help: "The name to greet")
  var name: String?


  func run() throws {
    // Setup an `EventLoopGroup` for the connection to run on.
    //
    // See: https://github.com/apple/swift-nio#eventloops-and-eventloopgroups
    let group = MultiThreadedEventLoopGroup(numberOfThreads: self.cores)

    // Make sure the group is shutdown when we're done with it.
    defer {
      try! group.syncShutdownGracefully()
    }

    print("test duration: \(self.duration) secs")
    print("cores:", self.cores)
    print("concurrent rpcs/core:", self.rpcsPerCore)
    print("connection pool:", self.useConnectionPool)

    let request = Helloworld_HelloRequest.with {
      $0.name = self.name ?? ""
    }

    let host = "127.0.0.1"

    if self.useConnectionPool {
      let pool = GRPCPooledClient(
        configuration: .init(
          group: group,
          maximumPoolSize: self.cores,
          host: host,
          port: self.port,
          queue: .init(label: "io.grpc.pool"),
          logger: .init(label: "io.grpc", factory: { _ in SwiftLogNoOpLogHandler() })
        )
      )

      defer {
        try! pool.close().wait()
      }

      let greeter = Helloworld_GreeterClient(channel: pool)
      queue.async {
        for _ in 0 ..< (self.cores * self.rpcsPerCore) {
          self.startAnRPC(client: greeter, request: request)
        }
      }

      self.waitForCompletion()
    } else {
      let channels = (0 ..< self.cores).map { _ in
        ClientConnection.insecure(group: group.next()).connect(host: host, port: self.port)
      }

      defer {
        channels.forEach {
          try! $0.close().wait()
        }
      }

      queue.async {
        for channel in channels {
          let greeter = Helloworld_GreeterClient(channel: channel)
          for _ in 0 ..< self.rpcsPerCore {
            self.startAnRPC(client: greeter, request: request)
          }
        }
      }

      self.waitForCompletion()
    }
  }

  private func waitForCompletion() {
    let workItem = DispatchWorkItem {
      running = false
      let totalRPCs = count

      print("rpcs:", totalRPCs)
      let perSecond = Double(totalRPCs) / Double(self.duration)
      print("rpcs/sec", perSecond)
      print("rpcs/sec/core:", perSecond / Double(self.cores))
    }

    queue.asyncAfter(deadline: .now() + .seconds(self.duration), execute: workItem)
    workItem.wait()
  }

  private func startAnRPC(client: Helloworld_GreeterClient, request: Helloworld_HelloRequest) {
    guard running else { return }

    let rpc = client.sayHello(request)
    rpc.status.whenComplete { _ in
      queue.async {
        count &+= 1
        self.startAnRPC(client: client, request: request)
      }
    }
  }
}

HelloWorld.main()
