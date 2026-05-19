//
//  World.swift
//  NIOSwiftMUD
//
//  Created by Engels, Maarten MAK on 19/05/2026.
//

struct World {
    let roomRepository: any Repository<Room>
    let userRepository: any UserRepository
}
