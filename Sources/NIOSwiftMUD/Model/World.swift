//
//  World.swift
//  NIOSwiftMUD
//
//  Created by Engels, Maarten MAK on 19/05/2026.
//

import Foundation

struct World {
    let roomRepository: any Repository<Room>
    let userRepository: any Repository<User>
    let doorRepository: any Repository<Door>
    
    func sendMessageToOtherPlayersInRoom(message: String, player: User) async -> [MudResponse] {
        let allPlayersInRoom = await userRepository.filter {
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
    
    func exitIsPassable(_ exit: Exit) async -> Bool {
        if let door = await doorRepository.find(exit.doorID) {
            return door.isOpen
        } else {
            return true
        }
    }
}


func makeExampleWorld() -> World {
    let doorRepository = InMemoryRepository<Door>(storage: [
        Door(id: UUID(uuidString: "D53F80E6-013A-4AA5-9D15-92B0EBE735DF")!, isOpen: false)
    ])
    
    let roomRepository = InMemoryRepository(storage: [
        Room(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, name: "The very first room", description: "Nothing special to see here.", exits: [
            Exit(direction: .North, targetRoomID: UUID(uuidString: "21C9D03A-ADEA-4120-A126-406C1D841BED")!, doorID: UUID(uuidString: "D53F80E6-013A-4AA5-9D15-92B0EBE735DF"))
        ]),
        Room(id: UUID(uuidString: "21C9D03A-ADEA-4120-A126-406C1D841BED")!, name: "The second room", description: "Nothing here either", exits: [
            Exit(direction: .South, targetRoomID: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, doorID: UUID(uuidString: "D53F80E6-013A-4AA5-9D15-92B0EBE735DF"))
        ])
    ])
    
    return World(roomRepository: roomRepository, userRepository: InMemoryRepository(), doorRepository: doorRepository)
}
