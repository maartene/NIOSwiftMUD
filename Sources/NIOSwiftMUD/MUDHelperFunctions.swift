//
//  File.swift
//  
//
//  Created by Maarten Engels on 08/11/2021.
//

import Foundation

func look(session: Session) async -> [MudResponse] {
    guard let user = await User.find(session.playerID) else {
        return [MudResponse(session: session, message: "Could not find player with id \(session.playerID).")]
    }
    
    guard let roomID = user.currentRoomID else {
        return [MudResponse(session: session, message: "You are in LIMBO!\n")]
    }
    
    guard let room = await Room.find(roomID) else {
        return [MudResponse(session: session, message: "Could not find room with roomID \(roomID).\n")]
    }
    
    return [MudResponse(session: session, message: room.formattedDescription)]
}

func createUser(session: Session, username: String, password: String) async -> [MudResponse] {
    var updatedSession = session
    let response: MudResponse
    
    do {
        let newUser = try await User.create(username: username, password: password)
        updatedSession.playerID = newUser.id
        response = MudResponse(session: updatedSession, message: "Welcome, \(newUser.username)!")
    } catch {
        response = MudResponse(session: updatedSession, message: "Error creating user: \(error)")
    }
    
    return [response]
}

func login(session: Session, username: String, password: String) async -> [MudResponse] {
    var updatedSession = session
    let response: MudResponse
    
    var notifications = [MudResponse]()
    
    do {
        let existingUser = try await User.login(username: username, password: password)
        updatedSession.playerID = existingUser.id
        response = MudResponse(session: updatedSession, message: "Welcome back, \(existingUser.username)!")
        
        if existingUser.currentRoomID != nil {
            notifications = await sendMessageToOtherPlayersInRoom(message: "\(existingUser.username) materialized out of thin air!", player: existingUser)
        }
    } catch {
        response = MudResponse(session: updatedSession, message: "Error logging in user: \(error)")
    }
    
    var result = [response]
    result.append(contentsOf: notifications)
    return result
}

func go(session: Session, direction: Direction) async -> [MudResponse] {
    guard var player = await User.find(session.playerID) else {
        return [MudResponse(session: session, message: "Player not found in session.")]
    }
    
    guard let currentRoom = await Room.find(player.currentRoomID) else {
        return  [MudResponse(session: session, message: "Cound not find room: \(String(describing: player.currentRoomID))")]
    }
    
    guard let exit = currentRoom.exits.first(where: {$0.direction == direction} ) else {
        return [MudResponse(session: session, message: "No exit found in direction \(direction).")]
    }
    
    guard let targetRoom = await Room.find(exit.targetRoomID) else {
        return [MudResponse(session: session, message: "Cound not find target room: \(String(describing: player.currentRoomID))")]
    }
    
    var response = [MudResponse]()
    response.append(MudResponse(session: session, message: "You moved into a new room: \n \(targetRoom.formattedDescription)"))
    
    let exitMessages = await sendMessageToOtherPlayersInRoom(message: "\(player.username) has left the room.", player: player)
    response.append(contentsOf: exitMessages)
    
    player.currentRoomID = exit.targetRoomID
    await player.save()
    
    let enterMessages = await sendMessageToOtherPlayersInRoom(message: "\(player.username) entered the room.", player: player)
    response.append(contentsOf: enterMessages)
    
    return response
}

func sendMessageToOtherPlayersInRoom(message: String, player: User) async -> [MudResponse] {
    let allPlayersInRoom = await User.filter {
        $0.currentRoomID == player.currentRoomID
    }
    
    let otherPlayers = allPlayersInRoom.filter { $0.id != player.id }
    
    var result = [MudResponse]()
    
    otherPlayers.forEach { otherPlayer in
        if let otherSession = SessionStorage.first(where: {$0.playerID == otherPlayer.id}) {
            result.append(MudResponse(session: otherSession, message: message))
        }
    }
    
    return result
}
