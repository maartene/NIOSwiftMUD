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
    
    typealias InboundIn = MudCommand
    typealias InboundOut = [MudResponse]
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        Task {
            let mudCommand = self.unwrapInboundIn(data)
            
            let response = await createMudResponse(mudCommand: mudCommand)
            
            context.eventLoop.execute {
                context.fireChannelRead(self.wrapInboundOut(response))
            }
        }
    }
    
    private func createMudResponse(mudCommand: MudCommand) async -> [MudResponse] {
        guard mudCommand.requiresLogin == false || mudCommand.session.playerID != nil else {
            return [MudResponse(session: mudCommand.session, message: "You need to be logged in to use this command.")]
        }
        
        return await mudCommand.execute()

//         switch verbCommand.verb {
//         case .close:
//             updatedSession.shouldClose = true
//             response = [MudResponse(session: updatedSession, message: "Good Bye!")]
//         case .createUser(let username, let password):
//            response  = await createUser(session: updatedSession, username: username, password: password)
//         case .login(let username, let password):
//             response = await login(session: updatedSession, username: username, password: password)
//         case .look:
//             response = await look(session: updatedSession)
//         case .go(let direction):
//             response = await go(session: updatedSession, direction: direction)
//         case .say(let sentence):
//             response = await sayMessage(session: updatedSession, sentence: sentence)
//         case .whisper(let targetUserName, let message):
//             response = await whisperMessage(to: targetUserName, message: message, session: updatedSession)
            
            
//         case .illegal:
//             response = [MudResponse(session: updatedSession, message: "This is not a well formed sentence.")]
//         case .empty:
//             response = [MudResponse(session: updatedSession, message: "\n")]
            
// //        default:
// //            response = [MudResponse(session: updatedSession, message: "Command not implemented yet.")]
//         }
        
        //return response
    }
}
