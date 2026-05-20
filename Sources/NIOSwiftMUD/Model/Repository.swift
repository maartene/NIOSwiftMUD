//
//  Repository.swift
//  NIOSwiftMUD
//
//  Created by Engels, Maarten MAK on 19/05/2026.
//

import Foundation

protocol Repository<T> {
    associatedtype T: Identifiable
    func find(_ id: T.ID?) async -> T?
    func count() async -> Int
    func save(_ object: T) async
    func filter(where predicate: (T) -> Bool) async -> [T]
}

extension Repository<User> {
    func find(_ username: String) async -> User? {
        await filter(where: { $0.username == username }).first
    }
}

final class InMemoryRepository<T: Identifiable>: Repository<T> {
    private var storage: [T] = []
    
    init(storage: [T] = []) {
        self.storage = storage
    }
    
    func find(_ id: T.ID?) async -> T? {
        storage.first(where: { $0.id == id })
    }
        
    func count() async -> Int {
        storage.count
    }
    
    func save(_ object: T) async {
        if let existingIndex = storage.firstIndex(where: { object.id == $0.id   }) {
            storage[existingIndex] = object
        } else {
            storage.append(object)
        }
    }
    
    func filter(where predicate: (T) -> Bool) async -> [T] {
        storage.filter(predicate)
    }
}
