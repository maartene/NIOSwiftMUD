//
//  File.swift
//  
//
//  Created by Maarten Engels on 08/11/2021.
//

import Foundation

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

func createUser(session: Session, username: String, password: String) async -> MudResponse {
    var updatedSession = session
    let response: MudResponse
    
    do {
        let newUser = try await User.create(username: username, password: password)
        updatedSession.playerID = newUser.id
        response = MudResponse(session: updatedSession, message: "Welcome, \(newUser.username)!")
    } catch {
        response = MudResponse(session: updatedSession, message: "Error creating user: \(error)")
    }
    
    return response
}

func login(session: Session, username: String, password: String) async -> MudResponse {
    var updatedSession = session
    let response: MudResponse
    
    do {
        let existingUser = try await User.login(username: username, password: password)
        updatedSession.playerID = existingUser.id
        response = MudResponse(session: updatedSession, message: "Welcome back, \(existingUser.username)!")
    } catch {
        response = MudResponse(session: updatedSession, message: "Error logging in user: \(error)")
    }
    
    return response
}
