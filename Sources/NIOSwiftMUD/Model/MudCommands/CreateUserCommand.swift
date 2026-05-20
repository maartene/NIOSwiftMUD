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
    
    func execute(in world: World) async -> [MudResponse] {
        var updatedSession = session
        let response: MudResponse
        
        do {
            guard await world.userRepository.find(username) == nil else {
                throw UserError.usernameAlreadyTaken
            }
            
            let newUser = User(username: username, password: password, currentRoomID: Room.STARTER_ROOM_ID)
            await world.userRepository.save(newUser)
            
            updatedSession.playerID = newUser.id
            response = MudResponse(session: updatedSession, message: "Welcome, \(newUser.username)!")
        } catch {
            response = MudResponse(session: updatedSession, message: "Error creating user: \(error)")
        }
        
        return [response]
    }
}
