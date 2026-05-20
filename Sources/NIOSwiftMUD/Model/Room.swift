//
//  Room.swift
//  
//
//  Created by Maarten Engels on 08/11/2021.
//

import Foundation

struct Room {
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
    
    static let STARTER_ROOM_ID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    
    var exitsAsString: String {
        let direction = exits.map { $0.direction.rawValue }
        return direction.joined(separator: " ")
    }
}

extension Room: Identifiable { }

struct Exit: Codable {
    let direction: Direction
    let targetRoomID: UUID
    let doorID: UUID?
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
    
    public init?(stringValue: String) {
        let capitalizedStringValue = stringValue.capitalized // NORTH --> North,  north --> North
        self.init(rawValue: capitalizedStringValue)
    }
}
