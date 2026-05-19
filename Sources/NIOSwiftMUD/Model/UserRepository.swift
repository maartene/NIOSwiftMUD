//
//  UserRepository.swift
//  NIOSwiftMUD
//
//  Created by Engels, Maarten MAK on 19/05/2026.
//

import Foundation

protocol UserRepository {
    func find(_ id: UUID?) async -> User?
    func count() async -> Int
    func save(_ user: User) async
}
