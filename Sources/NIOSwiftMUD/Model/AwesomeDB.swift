//
//  File.swift
//  
//
//  Created by Maarten Engels on 08/11/2021.
//

import Foundation

protocol DBType: Codable {
    static var storage: AwesomeDB<Self> { get }
    static var persist: Bool { get set }
    var id: UUID { get }
}

// MARK: Default implementation for default DB operations: `save`, `first`, `find` and `filter`.
extension DBType {
    func save() async {
        await Self.storage.replaceOrAddDatabaseObject(self)
        
        if Self.persist {
            await Self.storage.save()
        }
    }
    
    static func find(_ id: UUID?) async -> Self? {
        if id == nil {
            return nil
        }
        
        return await storage.first(where: {$0.id == id})
    }
    
    static func filter(where predicate: (Self) -> Bool) async -> [Self] {
        await Self.storage.filter(where: predicate)
    }
    
    static func first(where predicate: (Self) -> Bool) async -> Self? {
        await Self.storage.first(where: predicate)
    }

    static func count() async -> Int {
        await Self.storage.count()
    }
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
    
    func filter(where predicate: (DatabaseType) throws -> Bool) async -> [DatabaseType] {
        (try? storage.filter(predicate)) ?? []
    }

    func reloadStorage() async {
        storage = Self.loadStorage()
    }

    func count() async -> Int {
        storage.count
    }
}
