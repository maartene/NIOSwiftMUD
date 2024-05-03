struct SayCommand: MudCommand {
    static let token: String = "say"
    static let expectedArgumentCount = 1
    static let requiresLogin = true
    
    let session: Session
    let sentence: String
    
    static func create(_ arguments: [String], session: Session) -> Self? {
        guard arguments.count >= expectedArgumentCount else {
            return nil
        }
        
        return SayCommand(session: session, sentence: arguments.joined(separator: " "))
    }

    func execute() async -> [MudResponse] {
        guard let player = await User.find(session.playerID) else {
            return [MudResponse(session: session, message: couldNotFindPlayerMessage)]
        }
        
        var result = [MudResponse(session: session, message: "You say: \(sentence)")]
        
        result.append(contentsOf: await sendMessageToOtherPlayersInRoom(message: "\(player.username) says: \(sentence)", player: player))
        
        return result
    }
}