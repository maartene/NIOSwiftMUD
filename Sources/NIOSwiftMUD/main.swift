import NIO
import Foundation
import NIOSSH
import Dispatch

func main() async {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    do {
        let hostKey: NIOSSHPrivateKey
        if let existingKey = await SSHKey.first(where: { _ in true }) {
            hostKey = try existingKey.toNIOSSHPrivateKey()
            print("Reusing existing hostkey with id: \(existingKey.id)")
        } else {
            let newKey = SSHKey.initRandomKey()
            hostKey = try newKey.toNIOSSHPrivateKey()
            await newKey.save()
            print("Creating new hostkey with id: \(newKey.id)")
        }
                
//        let fixedKeyBase64b = "UIL9M6Utw/jiupzqq6F8EW4qySxAbgDS+wT7/RIjkJ4="
//        let fixedKeyData = Data(base64Encoded: fixedKeyBase64b)!
//        let hostKey = NIOSSHPrivateKey(ed25519Key: try! .init(rawRepresentation: fixedKeyData))
        
        // This should be default behaviour, but let's be specific
        User.persist = true
        Room.persist = true
        Door.persist = true
                
        let bootstrap = ServerBootstrap(group: group)
            // Pipeline
            .childChannelInitializer { channel in
                channel.pipeline.addHandlers([NIOSSHHandler(role: .server(.init(hostKeys: [hostKey], userAuthDelegate: NoLoginDelegate(), globalRequestDelegate: MUDGlobalRequestDelegate())), allocator: channel.allocator, inboundChildChannelInitializer: sshChildChannelInitializer(_:_:)), ErrorHandler()])
            }
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(IPPROTO_TCP), TCP_NODELAY), value: 1)
        
        let host = ProcessInfo.processInfo.environment["NIOSWIFTMUD_HOSTNAME"] ?? "::1"
        let port = Int(ProcessInfo.processInfo.environment["NIOSWIFTMUD_PORT"] ?? "2222") ?? 2222
        
        let channel = try await bootstrap.bind(host: host, port: port).get()
        
        print("Server started successfully, listening on address: \(channel.localAddress!)")
        
        try await channel.closeFuture.get()
        
        try await group.shutdownGracefully()
    } catch {
        print(error)
        do {
            try await group.shutdownGracefully()
        } catch {
            print(error)
        }
    }
}

//let mudCommandFactory = MudCommandFactory()

let dg = DispatchGroup()
dg.enter()
Task {
    await main()
    dg.leave()
}
dg.wait()

print("Server closed.")
