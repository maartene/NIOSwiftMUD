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
