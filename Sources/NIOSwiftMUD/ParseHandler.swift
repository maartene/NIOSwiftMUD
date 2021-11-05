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
            
            var updatedSession = verbCommand.session
            let response: MudResponse
            
            switch verbCommand.verb {
            case .close:
                updatedSession.shouldClose = true
                response = MudResponse(session: updatedSession, message: "Good Bye!")
            case .createUser(let username, let password):
                do {
                    let newUser = try await User.create(username: username, password: password)
                    updatedSession.playerID = newUser.id
                    response = MudResponse(session: updatedSession, message: "Welcome, \(newUser.username)!")
                } catch {
                    response = MudResponse(session: updatedSession, message: "Error creating user: \(error)")
                }
                
            case .login(let username, let password):
                do {
                    let existingUser = try await User.login(username: username, password: password)
                    updatedSession.playerID = existingUser.id
                    response = MudResponse(session: updatedSession, message: "Welcome back, \(existingUser.username)!")
                } catch {
                    response = MudResponse(session: updatedSession, message: "Error logging in user: \(error)")
                }
                
            case .illegal:
                response = MudResponse(session: updatedSession, message: "This is not a well formed sentence.")
            case .empty:
                response = MudResponse(session: updatedSession, message: "\n")
                
            default:
                response = MudResponse(session: updatedSession, message: "Command not implemented yet.")
            }
            
            context.eventLoop.execute {
                context.fireChannelRead(self.wrapInboundOut(response))
            }
        }
    }
}
