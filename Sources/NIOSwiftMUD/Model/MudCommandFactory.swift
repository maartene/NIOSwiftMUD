//
//  MudCommandFactory.swift
//  
//
//  Created by Maarten Engels on 01/11/2021.
//

import Foundation

class MudCommandFactory {
    let allCommands: [MudCommand.Type] = [
        IllegalCommand.self,
        EmptyCommand.self,
        CloseCommand.self,
        CreateUserCommand.self,
        LoginCommand.self,
        LookCommand.self,
        GoCommand.self
    ]
    // case illegal
    // case empty
    
    // // known commands
    // case close
    // case createUser(username: String, password: String)
    // case login(username: String, password: String)
    // case look
    // case go(direction: Direction)
    // case say(sentence: String)
    // case whisper(targetUserName: String, message: String)
    
    // var requiredLogin: Bool {
    //     switch self {
    //     case .close:
    //         return false
    //     case .createUser:
    //         return false
    //     case .login:
    //         return false
    //     default:
    //         return true
    //     }
    
    // }
    
    // static func expectedWordCount(verb: String) -> Int {
    //     switch verb.uppercased() {
    //     case "CREATE_USER":
    //         return 3
    //     case "LOGIN":
    //         return 3
    //     case "GO":
    //         return 2
    //     case "SAY":
    //         return 2
    //     case "WHISPER":
    //         return 3
    //     default:
    //         return 1
    //     }
    // }
    
    func createMudCommand(from str: String, session: Session) -> MudCommand {
        let trimmedString = str.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let parts = trimmedString.split(separator: " ")
        
        guard parts.count >= 1 && parts[0] != "" else {
            return EmptyCommand(session: session)
        }
    
        guard let commandType = allCommands.first (where: { $0.token.uppercased() == String(parts[0]).uppercased() }) else {
            return IllegalCommand(session: session, passedInCommand: trimmedString)
        }

        let arguments = Array(parts.dropFirst())
            .map { String($0) }

        guard let mudCommand = commandType.create(arguments, session: session) else {
            return IllegalCommand(session: session, passedInCommand: trimmedString)
        }

        return mudCommand
    }
}
