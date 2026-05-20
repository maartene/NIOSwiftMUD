struct GoCommand: MudCommand {
    static let token: String = "go"
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
        
        return GoCommand(session: session, direction: direction)
    }

    func execute(in world: World) async -> [MudResponse] {
        guard var player = await world.userRepository.find(session.playerID) else {
            return [MudResponse(session: session, message: couldNotFindPlayerMessage)]
        }
        
        guard let currentRoom = await world.roomRepository.find(player.currentRoomID) else {
            return  [MudResponse(session: session, message: "Cound not find room: \(String(describing: player.currentRoomID))")]
        }
        
        guard let exit = currentRoom.exits.first(where: {$0.direction == direction} ) else {
            return [MudResponse(session: session, message: "No exit found in direction \(direction).")]
        }
        
        guard let targetRoom = await world.roomRepository.find(exit.targetRoomID) else {
            return [MudResponse(session: session, message: "Cound not find target room: \(String(describing: player.currentRoomID))")]
        }
        
        guard await world.exitIsPassable(exit) else {
            return [MudResponse(session: session, message: "The exit is impassable.")]
        }
        
        var response = [MudResponse]()
        response.append(MudResponse(session: session, message: "You moved into a new room: \n \(targetRoom.formattedDescription)"))
        
        let exitMessages = await world.sendMessageToOtherPlayersInRoom(message: "\(player.username) has left the room.", player: player)
        response.append(contentsOf: exitMessages)
        
        player.currentRoomID = exit.targetRoomID
        await world.userRepository.save(player)
        
        let enterMessages = await world.sendMessageToOtherPlayersInRoom(message: "\(player.username) entered the room.", player: player)
        response.append(contentsOf: enterMessages)
        
        return response
    }
}
