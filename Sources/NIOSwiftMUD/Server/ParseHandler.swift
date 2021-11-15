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
        Task {
            let verbCommand = self.unwrapInboundIn(data)
            
            let response = await createMudResponse(verbCommand: verbCommand)
            
            context.eventLoop.execute {
                context.fireChannelRead(self.wrapInboundOut(response))
            }
        }
    }
    
    private func createMudResponse(verbCommand: VerbCommand) async -> MudResponse {
        var updatedSession = verbCommand.session
        let response: MudResponse
        
        guard verbCommand.verb.requiredLogin == false || updatedSession.playerID != nil else {
            return MudResponse(session: updatedSession, message: "You need to be logged in to use this command.")
        }
        
        switch verbCommand.verb {
        case .close:
            updatedSession.shouldClose = true
            response = MudResponse(session: updatedSession, message: "Good Bye!")
        case .createUser(let username, let password):
           response  = await createUser(session: updatedSession, username: username, password: password)
        case .login(let username, let password):
            response = await login(session: updatedSession, username: username, password: password)
        case .look:
            response = await look(session: updatedSession)
        case .go(let direction):
            response = await go(session: updatedSession, direction: direction)
            
            
            
        case .illegal:
            response = MudResponse(session: updatedSession, message: "This is not a well formed sentence.")
        case .empty:
            response = MudResponse(session: updatedSession, message: "\n")
            
        default:
            response = MudResponse(session: updatedSession, message: "Command not implemented yet.")
        }
        
        return response
    }
}
