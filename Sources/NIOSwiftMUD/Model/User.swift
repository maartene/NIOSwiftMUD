//
//  User.swift
//  
//
//  Created by Maarten Engels on 02/11/2021.
//

import Foundation

struct User {
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
}

enum UserError: Error {
    case usernameAlreadyTaken
    case userNotFound
    case passwordMismatch
}

extension User: Identifiable { }
