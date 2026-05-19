//
//  RoomRepository.swift
//  NIOSwiftMUD
//
//  Created by Engels, Maarten MAK on 19/05/2026.
//

import Foundation

protocol RoomRepository {
    func find(_ id: UUID?) async -> Room?
    func count() async -> Int
}
