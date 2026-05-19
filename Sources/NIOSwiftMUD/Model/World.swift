//
//  World.swift
//  NIOSwiftMUD
//
//  Created by Engels, Maarten MAK on 19/05/2026.
//

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
}
