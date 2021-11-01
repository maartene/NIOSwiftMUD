//
//  File.swift
//  
//
//  Created by Maarten Engels on 01/11/2021.
//

import Foundation

enum Verb {
    case illegal
    case empty
    
    // known commands
    case close
    
    static func createVerb(from str: String) -> Verb {
        let trimmedString = str.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let parts = trimmedString.split(separator: " ")
        
        guard parts.count >= 1 && parts[0] != "" else {
            return .empty
        }
        
        switch parts[0].uppercased() {
        case "CLOSE":
            return .close
        default:
            return .illegal
        }
    }
}
