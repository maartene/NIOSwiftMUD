//
//  HelpCommand.swift
//  
//
//  Created by Maarten Engels on 20/05/2023.
//

import Foundation

struct HelpCommand: MudCommand {
    static let HELP_STRING =
        """
        RECOGNIZED COMMANDS:
        ====================
        HELP: Shows this help message.
        CREATE_USER: Creates a new user. Usage: CREATE_USER <username> <password>
        LOGIN: Logs in a user. Usage: LOGIN <username> <password>
        CLOSE: Closes the connection.

        LOOK: Shows the description of the current room.
        GO: Moves the player in the specified direction. Usage: GO <direction>
        SAY: Sends a message to all players in the current room. Usage: SAY <message>
        WHISPER: Sends a message to a specific player. Usage: WHISPER <playername> <message>
        OPEN_DOOR: Opens a door in the current room. Usage: OPEN_DOOR <direction>

        For support: maarten@thedreamweb.eu or create an issue on GitHub:
        https://github.com/maartene/NIOSwiftMUD/issues
        """
    
    static let token: String = "help"
    static let expectedArgumentCount = 0
    static let requiresLogin = false
    
    let session: Session
    
    static func create(_ arguments: [String], session: Session) -> Self? {
        HelpCommand(session: session)
    }

    func execute() async -> [MudResponse] {
        return [MudResponse(session: session, message: Self.HELP_STRING)]
    }
}
