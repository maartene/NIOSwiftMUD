struct MudResponse {
    let session: Session
    let message: String
}

protocol MudCommand {
    static var token: String { get }
    static var expectedArgumentCount: Int { get }
    static var requiresLogin: Bool { get }

    var session: Session { get }

    static func create(_ arguments: [String], session: Session) -> Self?
    func execute() async -> [MudResponse]
}

extension MudCommand {
    var requiresLogin: Bool {
        Self.requiresLogin
    }

    var couldNotFindPlayerMessage: String {
        "Could not find player with id \(String(describing: session.playerID))."
    }
}

extension MudCommand {
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
}