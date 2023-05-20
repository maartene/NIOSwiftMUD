//
//  OpenDoorCommand.swift
//  
//
//  Created by Maarten Engels on 20/05/2023.
//

import Foundation

struct OpenDoorCommand: MudCommand {
    static let token: String = "open_door"
    static let expectedArgumentCount = 1
    static let requiresLogin = true
    
    let session: Session
    let direction: Direction
    
    static func create(_ arguments: [String], session: Session) -> Self? {
        guard arguments.count >= expectedArgumentCount else {
            return nil
        }

        guard let direction = Direction(stringValue: arguments[0]) else {
            return nil
        }
        
        return OpenDoorCommand(session: session, direction: direction)
    }

    func execute() async -> [MudResponse] {
        guard let player = await User.find(session.playerID) else {
            return [MudResponse(session: session, message: "Player not found in session.")]
        }
        
        guard let currentRoom = await Room.find(player.currentRoomID) else {
            return  [MudResponse(session: session, message: "Cound not find room: \(String(describing: player.currentRoomID))")]
        }
        
        guard let exit = currentRoom.exits.first(where: {$0.direction == direction} ) else {
            return [MudResponse(session: session, message: "No exit found in direction \(direction).")]
        }
        
        guard var door = await Door.find(exit.doorID) else {
            return [MudResponse(session: session, message: "No door to open in direction \(direction).")]
        }
        
        guard door.isOpen == false else {
            return [MudResponse(session: session, message: "Door direction \(direction) is already open.")]
        }
        
        door.isOpen = true
        await door.save()
        
        var response = [MudResponse]()
        response.append(MudResponse(session: session, message: "You opened the door in direction \(direction)."))
        
        let openMessage = await sendMessageToOtherPlayersInRoom(message: "\(player.username) has opened the door in direction \(direction).", player: player)
        response.append(contentsOf: openMessage)
        
        return response
    }
    
}
