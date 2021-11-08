//
//  File.swift
//  
//
//  Created by Maarten Engels on 08/11/2021.
//

import Foundation

struct Room: DBType {
    private static var allRooms: AwesomeDB<Room> = AwesomeDB()
    
    let id: UUID
    
    let name: String
    let description: String
    let exits: [Exit]
    
    var formattedDescription: String {
        """
            \(name)
            \(description)
            There are exits: \(exitsAsString)
        
        """
    }
    
    var exitsAsString: String {
        let direction = exits.map { $0.direction.rawValue }
        return direction.joined(separator: " ")
    }
    
    static func find(_ id: UUID?) async -> Room? {
        if id == nil {
            return nil
        }
        
        return await allRooms.first(where: {$0.id == id})
    }
    
}

struct Exit: Codable {
    let direction: Direction
    let targetRoomID: UUID
}


enum Direction: String, Codable {
    case North
    case South
    case East
    case West
    case Up
    case Down
    case In
    case Out
    
    var opposite: Direction {
        switch self {
        case .North:
            return .South
        case .South:
            return .North
        case .East:
            return .West
        case .West:
            return .East
        case .Up:
            return .Down
        case .Down:
            return .Up
        case .In:
            return .Out
        case .Out:
            return .In
        }
    }
}
