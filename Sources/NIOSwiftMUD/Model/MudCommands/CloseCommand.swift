struct CloseCommand: MudCommand {
    static let token: String = "close"
    static let expectedArgumentCount = 0
    static let requiresLogin = false
    
    let session: Session
    
    static func create(_ arguments: [String], session: Session) -> Self? {
        return CloseCommand(session: session)
    }

    func execute() async -> [MudResponse] {
        var updatedSession = session 
        updatedSession.shouldClose = true
        return [MudResponse(session: updatedSession, message: "Good Bye!")]
    }
}