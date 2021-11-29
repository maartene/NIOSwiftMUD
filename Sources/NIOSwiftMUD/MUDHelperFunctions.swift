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
    
    let otherPlayersInRoom = await User.filter(where: {$0.currentRoomID == roomID})
        .filter({$0.id != user.id})
    
    let playerString = "Players:\n" + otherPlayersInRoom.map {$0.username}.joined(separator: ", ")
    
    return [MudResponse(session: session, message: room.formattedDescription + "\n" + playerString)]
}

func createUser(session: Session, username: String, password: String) async -> [MudResponse] {
    var updatedSession = session
    let response: MudResponse
    
    do {
        let newUser = try await User.create(username: username, password: password, currentRoomID: Room.STARTER_ROOM_ID)
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

func sayMessage(session: Session, sentence: String) async -> [MudResponse] {
    guard let player = await User.find(session.playerID) else {
        return [MudResponse(session: session, message: "Player not found in session.")]
    }
    
    var result = [MudResponse(session: session, message: "You say: \(sentence)")]
    
    result.append(contentsOf: await sendMessageToOtherPlayersInRoom(message: "\(player.username) says: \(sentence)", player: player))
    
    return result
}

func whisperMessage(to targetPlayerName: String, message: String, session: Session) async -> [MudResponse] {
    guard let player = await User.find(session.playerID) else {
        return [MudResponse(session: session, message: "Player not found in session.")]
    }
    
    guard let targetPlayer = await User.filter(where: {$0.username.uppercased() == targetPlayerName.uppercased()}).first else {
        return [MudResponse(session: session, message: "There is no player \(targetPlayerName) in the game.")]
    }
    
    guard player.currentRoomID == targetPlayer.currentRoomID else {
        return [MudResponse(session: session, message: "You can only whisper to other players in the room.")]
    }
    
    guard let targetPlayerSession = SessionStorage.first(where: {$0.playerID == targetPlayer.id }) else {
        return [MudResponse(session: session, message: "You can only whisper to players that are logged in.")]
    }
    
    var result = [MudResponse(session: session, message: "You whisper to \(targetPlayerName): \(message)")]
    
    result.append(MudResponse(session: targetPlayerSession, message: "\(player.username) whispers to you: \(message)"))
    
    let playersInRoom = await User.filter(where: {$0.currentRoomID == player.currentRoomID})
    
    playersInRoom.forEach { otherPlayer in
        if otherPlayer.id != player.id && otherPlayer.id != targetPlayer.id {
            if let otherSession = SessionStorage.first(where: {$0.playerID == otherPlayer.id}) {
                result.append(MudResponse(session: otherSession, message: "\(player.username) whispers something to \(targetPlayerName), but you can't quite make out what is said."))
            }
        }
    }
    
    return result
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
