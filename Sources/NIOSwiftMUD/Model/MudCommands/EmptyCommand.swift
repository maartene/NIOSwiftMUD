struct EmptyCommand: MudCommand {
    static let token: String = "empty"
    static let expectedArgumentCount = 0
    static let requiresLogin = false
    
    let session: Session
    
    static func create(_ arguments: [String], session: Session) -> Self? {
        EmptyCommand(session: session)
    }

    func execute(in world: World) async -> [MudResponse] {
        return [MudResponse(session: session, message: "")]
    }
}
