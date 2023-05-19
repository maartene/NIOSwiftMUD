struct CreateUserCommand: MudCommand {
    static let token: String = "create_user"
    static let expectedArgumentCount = 2
    static let requiresLogin = false
    
    let session: Session
    let username: String
    let password: String
    
    static func create(_ arguments: [String], session: Session) -> Self? {
        guard arguments.count >= expectedArgumentCount else {
            return nil
        }

        return CreateUserCommand(session: session, username: arguments[0], password: arguments[1])
    }

    func execute() async -> [MudResponse] {
        var updatedSession = session
        let response: MudResponse
        
        do {
            let newUser = try await User.create(username: username, password: password, currentRoomID: Room.STARTER_ROOM_ID)
            updatedSession.playerID = newUser.id
            response = MudResponse(session: updatedSession, message: "Welcome, \(newUser.username)!")
        } catch {
            response = MudResponse(session: updatedSession, message: "Error creating user: \(error)")
        }
        
        return [response]
    }
}