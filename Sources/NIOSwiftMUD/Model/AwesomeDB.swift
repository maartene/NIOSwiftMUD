//
//  File.swift
//  
//
//  Created by Maarten Engels on 08/11/2021.
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
    
    func filter(where predicate: (DatabaseType) throws -> Bool) async -> [DatabaseType] {
        (try? storage.filter(predicate)) ?? []
    }
}
