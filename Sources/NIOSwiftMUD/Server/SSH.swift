//
//  SSH.swift
//  
//
//  Created by Maarten Engels on 20/01/2023.
//

import Foundation
import NIOSSH
import NIO
import Crypto

enum SSHServerError: Error {
    case invalidCommand
    case invalidDataType
    case invalidChannelType
    case alreadyListening
    case notListening
}

final class MUDGlobalRequestDelegate: GlobalRequestDelegate {
    
}

final class ErrorHandler: ChannelInboundHandler {
    typealias InboundIn = Any

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Error in pipeline: \(error)")
        context.close(promise: nil)
    }
}

/// This always succeeds. So we can use our own login methods
final class NoLoginDelegate: NIOSSHServerUserAuthenticationDelegate {
    var supportedAuthenticationMethods: NIOSSHAvailableUserAuthenticationMethods {
        .all
    }

    func requestReceived(request: NIOSSHUserAuthenticationRequest, responsePromise: EventLoopPromise<NIOSSHUserAuthenticationOutcome>) {
        responsePromise.succeed(.success)
    }
}

/// Adds the MUD business-logic handlers to a channel synchronously.
/// Use this in tests (EmbeddedChannel) and within the event loop in production.
/// sshChildChannelInitializer prepends BackPressureHandler for real TCP connections.
func configureMUDPipeline(_ channel: Channel, world: World) throws {
    try channel.pipeline.syncOperations.addHandlers([
        SessionHandler(), VerbHandler(), ParseHandler(world: world), ResponseHandler()
    ])
}

func sshChildChannelInitializer(_ channel: Channel, _ channelType: SSHChannelType, world: World) -> EventLoopFuture<Void> {
    switch channelType {
    case .session:
        do {
            try channel.pipeline.syncOperations.addHandler(BackPressureHandler())
            try configureMUDPipeline(channel, world: world)
            return channel.eventLoop.makeSucceededVoidFuture()
        } catch {
            return channel.eventLoop.makeFailedFuture(error)
        }
    default:
        print("\(channelType) connections are not supported. Only session channels are supported.")
        return channel.eventLoop.makeFailedFuture(SSHServerError.invalidChannelType)
    }
}

extension SSHChannelData {
    init(byteBuffer: ByteBuffer) {
        let ioData = IOData.byteBuffer(byteBuffer)
        self.init(type: .channel, data: ioData)
    }
}

struct SSHKey {
    enum SSHKeyError: Error {
        case invalidBase64String
    }
    
    let id: UUID
    let base64Key: String
    
    static func initRandomKey() -> SSHKey {
        let ed25519Key = Curve25519.Signing.PrivateKey()
        let base64Key = ed25519Key.rawRepresentation.base64EncodedString()
        return SSHKey(id: UUID(), base64Key: base64Key)
    }
    
    func toNIOSSHPrivateKey() throws -> NIOSSHPrivateKey {
        guard let keyData = Data(base64Encoded: base64Key) else {
            throw SSHKeyError.invalidBase64String
        }
        
        let key = try Curve25519.Signing.PrivateKey(rawRepresentation: keyData)
        
        return NIOSSHPrivateKey(ed25519Key: key)
    }
}
