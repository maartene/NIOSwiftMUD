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
}

extension Repository where T == User {
    func find(_ username: String) async -> User? {
        nil
    }
}
