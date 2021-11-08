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
            
            if verbCommand.verb.requiredLogin && updatedSession.playerID == nil {
                response = MudResponse(session: updatedSession, message: "You need to be logged in to use this command.")
            } else {
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
                    
                case .look:
                    response = await look(session: updatedSession)
                case .illegal:
                    response = MudResponse(session: updatedSession, message: "This is not a well formed sentence.")
                case .empty:
                    response = MudResponse(session: updatedSession, message: "\n")
                    
                default:
                    response = MudResponse(session: updatedSession, message: "Command not implemented yet.")
                }
            }
            
            context.eventLoop.execute {
                context.fireChannelRead(self.wrapInboundOut(response))
            }
        }
    }
}

func look(session: Session) async -> MudResponse {
    guard let user = await User.find(session.playerID) else {
        return MudResponse(session: session, message: "Could not find player with id \(session.playerID).")
    }
    
    guard let roomID = user.currentRoomID else {
        return MudResponse(session: session, message: "You are in LIMBO!\n")
    }
    
    guard let room = await Room.find(roomID) else {
        return MudResponse(session: session, message: "Could not find room with roomID \(roomID).\n")
    }
    
    return MudResponse(session: session, message: room.formattedDescription)
}
