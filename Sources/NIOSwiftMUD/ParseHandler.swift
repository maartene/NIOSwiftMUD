//
//  File.swift
//  
//
//  Created by Maarten Engels on 01/11/2021.
//

import Foundation
import NIO

struct MudResponse {
    let session: Session
    let message: String
}

final class ParseHandler: ChannelInboundHandler {
    
    typealias InboundIn = VerbCommand
    typealias InboundOut = MudResponse
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let verbCommand = self.unwrapInboundIn(data)
        
        var updatedSession = verbCommand.session
        let response: MudResponse
        
        switch verbCommand.verb {
        case .close:
            updatedSession.shouldClose = true
            response = MudResponse(session: updatedSession, message: "Good Bye!")
    
        case .illegal:
            response = MudResponse(session: updatedSession, message: "This is not a well formed sentence.")
        case .empty:
            response = MudResponse(session: updatedSession, message: "\n")
            
        default:
            response = MudResponse(session: updatedSession, message: "Command not implemented yet.")
        }
        
            
        context.fireChannelRead(wrapInboundOut(response))
    }
}