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
        GoCommand.self,
        SayCommand.self,
        WhisperCommand.self
    ]
    
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
