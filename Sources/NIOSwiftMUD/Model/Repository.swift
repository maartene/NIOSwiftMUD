//
//  Repository.swift
//  NIOSwiftMUD
//
//  Created by Engels, Maarten MAK on 19/05/2026.
//

import Foundation

protocol Repository<T> {
    associatedtype T: Identifiable
    func find(_ id: UUID?) async -> T?
    func count() async -> Int
    func save(_ object: T) async
    func filter(where predicate: (T) -> Bool) async -> [T]
}

protocol UserRepository: Repository<User> {
    func find(_ username: String) async -> User?
}
