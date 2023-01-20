import NIO
import Foundation
import NIOSSH

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
defer {
    try! group.syncShutdownGracefully()
}



// We need a host key. We can generate a fixed one or generate one on the fly
//let key  = Curve25519.Signing.PrivateKey()
//let keyData = key.rawRepresentation
//let keyDataBase64 = keyData.base64EncodedString()
//print(keyDataBase64)

let fixedKeyBase64b = "UIL9M6Utw/jiupzqq6F8EW4qySxAbgDS+wT7/RIjkJ4="
let fixedKeyData = Data(base64Encoded: fixedKeyBase64b)!
let hostKey = NIOSSHPrivateKey(ed25519Key: try! .init(rawRepresentation: fixedKeyData))

let bootstrap = ServerBootstrap(group: group)
    //.serverChannelOption(ChannelOptions.backlog, value: 256)
    //.serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)


    // Pipeline
    .childChannelInitializer { channel in
        channel.pipeline.addHandlers([NIOSSHHandler(role: .server(.init(hostKeys: [hostKey], userAuthDelegate: NoLoginDelegate(), globalRequestDelegate: MUDGlobalRequestDelegate())), allocator: channel.allocator, inboundChildChannelInitializer: sshChildChannelInitializer(_:_:)), ErrorHandler()])
    }
    .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(IPPROTO_TCP), TCP_NODELAY), value: 1)
    .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
//    .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
//    .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
//    .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

let host = ProcessInfo.processInfo.environment["NIOSWIFTMUD_HOSTNAME"] ?? "::1"
let port = Int(ProcessInfo.processInfo.environment["NIOSWIFTMUD_PORT"] ?? "2222") ?? 2222

let channel = try bootstrap.bind(host: host, port: port).wait()

print("Server started successfully, listening on address: \(channel.localAddress!)")

try channel.closeFuture.wait()

print("Server closed.")
