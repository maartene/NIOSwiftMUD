struct LookCommand: MudCommand {
    static let token: String = "look"
    static let expectedArgumentCount = 0
    static let requiresLogin = true
    
    let session: Session
    
    static func create(_ arguments: [String], session: Session) -> Self? {
        return LookCommand(session: session)
    }

    func execute() async -> [MudResponse] {
        guard let user = await User.find(session.playerID) else {
            return [MudResponse(session: session, message: "Could not find player with id \(String(describing: session.playerID)).")]
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
        
        return [MudResponse(session: session, message: room.formattedDescription + playerString)]
    }
}