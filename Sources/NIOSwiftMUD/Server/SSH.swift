//
//  SSH.swift
//  
//
//  Created by Maarten Engels on 20/01/2023.
//

import Foundation
import NIOSSH
import NIO

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

func sshChildChannelInitializer(_ channel: Channel, _ channelType: SSHChannelType) -> EventLoopFuture<Void> {
    switch channelType {
    case .session:
        return channel.pipeline.addHandlers([BackPressureHandler(), SessionHandler(), VerbHandler(), ParseHandler(), ResponseHandler()])
    case .directTCPIP:
        print("DirectTCPIP connections are not supported. Only session channels are supported.")
        return channel.eventLoop.makeFailedFuture(SSHServerError.invalidChannelType)
    case .forwardedTCPIP:
        print("DirectTCPIP connections are not supported. Only session channels are supported.")
        return channel.eventLoop.makeFailedFuture(SSHServerError.invalidChannelType)
    }
}
