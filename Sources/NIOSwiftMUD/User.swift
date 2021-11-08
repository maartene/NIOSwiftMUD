//
//  File.swift
//  
//
//  Created by Maarten Engels on 02/11/2021.
//

import Foundation

protocol DBType: Codable {
    var id: UUID { get }
}

actor AwesomeDB<DatabaseType: DBType> {
    
    // type: User, filename: users.json
    // type: Room, filename: rooms.json
    
    static private var filename: String {
        dbName + ".json"
    }
    
    static private var dbName: String {
        "\(DatabaseType.self)".lowercased() + "s"
    }
    
    private var storage: [DatabaseType] = AwesomeDB.loadStorage()
    
    private static func loadStorage() -> [DatabaseType] {
        if FileManager.default.fileExists(atPath: filename) {
            print("try loading data from file: \(filename)")
            if let data = FileManager.default.contents(atPath: filename) {
                do {
                    let decoder = JSONDecoder()
                    return try decoder.decode([DatabaseType].self, from: data)
                } catch {
                    print("Error reading data: \(error).")
                }
            }
            
        } else {
            print("File \(filename) not found.")
        }
        
        return []
    }
    
    func save() async {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(storage)
            let url = URL(fileURLWithPath: Self.filename)
            try data.write(to: url)
            print("Saved data fo file: \(url)")
        } catch {
            print("Error writing data: \(error).")
        }
    }
    
    func replaceOrAddDatabaseObject(_ databaseObject: DatabaseType) async {
        if let existingObjectIndex = storage.firstIndex(where: { $0.id == databaseObject.id }) {
            storage[existingObjectIndex] = databaseObject
        } else {
            storage.append(databaseObject)
        }
    }
    
    func first(where predicate: (DatabaseType) throws -> Bool) async -> DatabaseType? {
        try? storage.first(where: predicate)
    }
}

struct User: DBType {
    private static var allUsers: AwesomeDB<User> = AwesomeDB()
    
    let id: UUID
    let username: String
    let hashedPassword: String
    var currentRoomID: UUID?
    
    init(id: UUID? = nil, username: String, password: String) {
        self.id = id ?? UUID()
        self.username = username
        
        self.hashedPassword = Hasher.hash(password + username)
    }
    
    static func create(username: String, password: String) async throws -> User {
        guard await User.first(username: username) == nil else {
            throw UserError.usernameAlreadyTaken
        }
                
        let player = User(id: UUID(), username: username, password: password)
        await player.save()
        return player
    }
    
    static func login(username: String, password: String) async throws -> User {
        guard let user = await User.first(username: username) else {
            throw UserError.userNotFound
        }
        
        guard Hasher.verify(password: password + username, hashedPassword: user.hashedPassword) else {
            throw UserError.passwordMismatch
        }
        
        return user
    }
    
    static func first(username: String) async -> User? {
        await allUsers.first(where: { $0.username == username })
    }
    
    static func find(_ id: UUID?) async -> User? {
        if id == nil {
            return nil
        }
        
        return await allUsers.first(where: { $0.id == id })
    }
    
    func save() async {
        await Self.allUsers.replaceOrAddDatabaseObject(self)
        
        await Self.allUsers.save()
    }
}

enum UserError: Error {
    case usernameAlreadyTaken
    case userNotFound
    case passwordMismatch
}
