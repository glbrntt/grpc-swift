import GRPC
import GRPCInteroperabilityTestModels
import NIO
import Logging
import Foundation

let logger = Logger(label: "zipbomb")

func main(
  host: String,
  port: Int,
  concurrentConnections: Int
) {
  let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
  defer {
    try! group.syncShutdownGracefully()
  }

  let channels: [GRPCChannel] = (0..<concurrentConnections).map { index in
    logger.info("creating channel", metadata: ["index": "\(index)"])
    return ClientConnection.insecure(group: group).connect(host: host, port: port)
  }
  defer {
    channels.enumerated().forEach { index, channel in
      channel.close().whenComplete { result in
        logger.info("closed channel", metadata: ["index": "\(index)", "result": "\(result)"])
      }
    }
  }

  let request = Grpc_Testing_SimpleRequest.with {
    $0.expectCompressed = .with {
      $0.value = true
    }
    // The C++ Protobuf trips up with payloads of around 1GB it seems.
    $0.payload = .with {
      $0.body = Data(repeating: 0, count: (1024 * 1024 * 1024) - 100)
    }
  }

  let options = CallOptions(messageEncoding: .enabled(.init(forRequests: .gzip, decompressionLimit: .absolute(1024 * 1024))))

  let status = channels.enumerated().map { index, channel -> EventLoopFuture<GRPCStatus> in
    let client = Grpc_Testing_TestServiceClient(channel: channel, defaultCallOptions: options)
    logger.info("making request", metadata: ["index": "\(index)"])
    let rpc = client.unaryCall(request)
    rpc.status.whenSuccess {
      logger.info("rpc completed", metadata: ["index": "\(index)", "status": "\($0.code)"])
    }
    return rpc.status
  }

  logger.info("waiting for rpcs to complete...")
  do {
    try EventLoopFuture.andAllComplete(status, on: group.next()).wait()
    logger.info("done!")
  } catch {
    logger.error("error: \(error)")
  }
}

// MARK: - CLI

// Quieten the logs.
LoggingSystem.bootstrap { label in
  var handler = StreamLogHandler.standardOutput(label: label)
  if label.starts(with: "io.grpc") {
    handler.logLevel = .error
  } else {
    handler.logLevel = .info
  }
  return handler
}

let args = CommandLine.arguments
let maybeHost = args.dropFirst().first
let maybePort = args.dropFirst(2).first.flatMap(Int.init)
let maybeNumberOfConnections = args.dropFirst(3).first.flatMap(Int.init)

switch (maybeHost, maybePort) {
case let (.some(host), .some(port)):
  main(host: host, port: port, concurrentConnections: maybeNumberOfConnections ?? 1)
default:
  print("Usage: \(args[0]) HOST PORT [NUM_CONNECTIONS]")
  exit(1)
}
