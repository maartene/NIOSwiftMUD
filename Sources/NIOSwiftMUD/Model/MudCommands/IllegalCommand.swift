struct IllegalCommand: MudCommand {
    static let token: String = "illegal"
    static let expectedArgumentCount = 0
    static let requiresLogin = false
    
    let session: Session
    let passedInCommand: String
    
    static func create(_ arguments: [String], session: Session) -> Self? {
        IllegalCommand(session: session, passedInCommand: arguments.joined())
    }

    func execute() async -> [MudResponse] {
        return [MudResponse(session: session, message: "`\(passedInCommand)` is not a valid command.")]
    }
}