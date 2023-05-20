//
//  MudCommandFactoryTests.swift
//  
//
//  Created by Maarten Engels on 20/05/2023.
//

import XCTest
@testable import NIOSwiftMUD

final class MudCommandFactoryTests: XCTestCase {
    struct MockSession: Session {
        let id: UUID
        var playerID: UUID?
        var shouldClose = false
        var currentString = ""
        
        init() {
            self.id = UUID()
        }
    }
    
    let commandFactory = MudCommandFactory()
    
    func test_HelpCommand_create() {
        let inputString = "  help   "
        
        let command = commandFactory.createMudCommand(from: inputString, session: MockSession())
        
        guard command is HelpCommand else {
            XCTFail("Expected an HelpCommand instance, but got \(command).")
            return
        }
    }
    
    func test_CloseCommand_create() {
        let inputString = "  close   "
        
        let command = commandFactory.createMudCommand(from: inputString, session: MockSession())
        
        guard command is CloseCommand else {
            XCTFail("Expected an CloseCommand instance, but got \(command).")
            return
        }
    }

}
