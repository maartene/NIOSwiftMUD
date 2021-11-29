import NIO
import Foundation

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

let bootstrap = ServerBootstrap(group: group)
    .serverChannelOption(ChannelOptions.backlog, value: 256)
    .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)


    // Pipeline
    // BackPressureHandler (ByteBuffer) -> SessionHandler (TextCommand) -> VerbHandler (VerbCommand) -> ParseHandler (MudResponse) -> ResponseHandler (ByteBuffer)
    .childChannelInitializer { channel in
        channel.pipeline.addHandlers([BackPressureHandler(), SessionHandler(), VerbHandler(), ParseHandler(), ResponseHandler()])
    }

    .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
    .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
    .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

let host = ProcessInfo.processInfo.environment["NIOSWIFTMUD_HOSTNAME"] ?? "::1"
let port = Int(ProcessInfo.processInfo.environment["NIOSWIFTMUD_PORT"] ?? "8888") ?? 8888

let channel = try bootstrap.bind(host: host, port: port).wait()

print("Server started successfully, listening on address: \(channel.localAddress!)")

try channel.closeFuture.wait()

print("Server closed.")
