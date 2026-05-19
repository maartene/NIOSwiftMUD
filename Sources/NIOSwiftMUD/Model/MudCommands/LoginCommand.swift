struct LoginCommand: MudCommand {
    static let token: String = "login"
    static let expectedArgumentCount = 2
    static let requiresLogin = false
    
    let session: Session
    let username: String
    let password: String
    
    static func create(_ arguments: [String], session: Session) -> Self? {
        guard arguments.count >= expectedArgumentCount else {
            return nil
        }

        return LoginCommand(session: session, username: arguments[0], password: arguments[1])
    }

    func execute() async -> [MudResponse] {
        var updatedSession = session
        let response: MudResponse
        
        var notifications = [MudResponse]()
        
        do {
            let existingUser = try await User.login(username: username, password: password)
            updatedSession.playerID = existingUser.id
            response = MudResponse(session: updatedSession, message: "Welcome back, \(existingUser.username)!")
            
            if existingUser.currentRoomID != nil {
                notifications = await sendMessageToOtherPlayersInRoom(message: "\(existingUser.username) materialized out of thin air!", player: existingUser)
            }
        } catch {
            response = MudResponse(session: updatedSession, message: "Error logging in user: \(error)")
        }
        
        var result = [response]
        result.append(contentsOf: notifications)
        return result
    }
    
    func execute(in world: World) async -> [MudResponse] {
        var updatedSession = session
        let response: MudResponse
        
        var notifications = [MudResponse]()

        do {
            guard let existingUser = await world.userRepository.find(username) else {
                throw UserError.userNotFound
            }
            
            guard Hasher.verify(password: password + username.uppercased(), hashedPassword: existingUser.hashedPassword) else {
                throw UserError.passwordMismatch
            }
            
            updatedSession.playerID = existingUser.id
            response = MudResponse(session: updatedSession, message: "Welcome back, \(existingUser.username)!")
            
            if existingUser.currentRoomID != nil {
                notifications = await sendMessageToOtherPlayersInRoom(message: "\(existingUser.username) materialized out of thin air!", player: existingUser)
            }
        } catch {
            response = MudResponse(session: updatedSession, message: "Error logging in user: \(error)")
        }
        
        var result = [response]
        result.append(contentsOf: notifications)
        return result
    }
}
