//
//  User.swift
//  
//
//  Created by Maarten Engels on 02/11/2021.
//

import Foundation

struct User: DBType {
    static var storage: AwesomeDB<User> = AwesomeDB()
    static var persist = true
    
    let id: UUID
    let username: String
    let hashedPassword: String
    var currentRoomID: UUID?
    
    init(id: UUID? = nil, username: String, password: String, currentRoomID: UUID? = nil) {
        self.id = id ?? UUID()
        self.username = username
        self.currentRoomID = currentRoomID
        
        self.hashedPassword = Hasher.hash(password + username.uppercased())
    }
    
    static func create(username: String, password: String, currentRoomID: UUID? = nil) async throws -> User {
        guard await User.first(username: username) == nil else {
            throw UserError.usernameAlreadyTaken
        }
                
        let player = User(id: UUID(), username: username, password: password, currentRoomID: currentRoomID)
        await player.save()
        return player
    }
    
    static func login(username: String, password: String) async throws -> User {
        guard let user = await User.first(username: username) else {
            throw UserError.userNotFound
        }
        
        guard Hasher.verify(password: password + username.uppercased(), hashedPassword: user.hashedPassword) else {
            throw UserError.passwordMismatch
        }
        
        return user
    }
        
    static func first(username: String) async -> User? {
        await storage.first(where: { $0.username.uppercased() == username.uppercased() })
    }
}

enum UserError: Error {
    case usernameAlreadyTaken
    case userNotFound
    case passwordMismatch
}
