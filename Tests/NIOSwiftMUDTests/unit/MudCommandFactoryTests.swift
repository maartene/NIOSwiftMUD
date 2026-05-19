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
    
    // MARK: Test failure cases
    func test_CreateCommand_fails_forUnknownToken() {
        // Let's assume a command will never take the for of a UUID string.
        let inputString = UUID().uuidString
        let command = commandFactory.createMudCommand(from: inputString, session: MockSession())
        
        XCTAssertTrue(command is IllegalCommand, "Expected an IllegalCommand instance, but got \(command).")
    }
    
    func test_CreateCommand_fails_forEmptyInputString() {
        let command = commandFactory.createMudCommand(from: "", session: MockSession())
        
        XCTAssertTrue(command is EmptyCommand, "Expected an EmptyCommand instance, but got \(command).")
    }
    
    func test_CreateCommand_fails_withoutArguments() {
        let commandTypesThatRequireArguments = commandFactory.allCommands.filter { $0.expectedArgumentCount > 0 }
        
        for commandType in commandTypesThatRequireArguments {
            let inputString = commandType.token
            let command = commandFactory.createMudCommand(from: inputString, session: MockSession())
            
            XCTAssertTrue(command is IllegalCommand, "Expected an IllegalCommand instance, but got \(command).")
        }
    }
    
    func test_CreateCommand_fails_withInsufficientArguments() {
        let commandTypesThatRequireArguments = commandFactory.allCommands.filter { $0.expectedArgumentCount > 0 }
        
        for commandType in commandTypesThatRequireArguments {
            let argumentsToCreate = commandType.expectedArgumentCount - 1
            let arguments = Array(repeating: "argument", count: argumentsToCreate)
            let inputString = commandType.token + arguments.joined(separator: " ")
            let command = commandFactory.createMudCommand(from: inputString, session: MockSession())
            
            XCTAssertTrue(command is IllegalCommand, "Expected an IllegalCommand instance, but got \(command).")
        }
    }
    
    // MARK: Test individual commands
    func test_HelpCommand_create() {
        let inputString = "  help   "
        
        let command = commandFactory.createMudCommand(from: inputString, session: MockSession())
        
        XCTAssertTrue(command is HelpCommand, "Expected an HelpCommand instance, but got \(command).")
    }
    
    func test_CloseCommand_create() {
        let inputString = "  close   "
        
        let command = commandFactory.createMudCommand(from: inputString, session: MockSession())
        
        XCTAssertTrue(command is CloseCommand, "Expected an CloseCommand instance, but got \(command).")
    }
    
    func test_CreateUserCommand_create() {
        let username = "foo"
        let password = "bar"
        let inputString = "  create_user   \(username)  \(password)   "
        
        let command = commandFactory.createMudCommand(from: inputString, session: MockSession())
        
        guard let createUserCommand = command as? CreateUserCommand else {
            XCTFail("Expected an CreateUserCommand instance, but got \(command).")
            return
        }
        
        XCTAssertEqual(createUserCommand.username, username)
        XCTAssertEqual(createUserCommand.password, password)
    }
    
    func test_LoginCommand_create() {
        let username = "foo"
        let password = "bar"
        let inputString = "  login   \(username)  \(password)   "
        
        let command = commandFactory.createMudCommand(from: inputString, session: MockSession())
        
        guard let loginCommand = command as? LoginCommand else {
            XCTFail("Expected an LoginCommand instance, but got \(command).")
            return
        }
        
        XCTAssertEqual(loginCommand.username, username)
        XCTAssertEqual(loginCommand.password, password)
    }
    
    func test_LoookCommand_create() {
        let inputString = "  look   "
        
        let command = commandFactory.createMudCommand(from: inputString, session: MockSession())
        
        XCTAssertTrue(command is LookCommand)
    }

    func test_GoCommand_create() {
        let direction = Direction.East
        let inputString = "  go   \(direction.rawValue)       "
        
        let command = commandFactory.createMudCommand(from: inputString, session: MockSession())
        
        guard let goCommand = command as? GoCommand else {
            XCTFail("Expected an GoCommand instance, but got \(command).")
            return
        }
        
        XCTAssertEqual(goCommand.direction, direction)
    }
    
    func test_OpenDoorCommand_create() {
        let direction = Direction.East
        let inputString = "  open_door   \(direction.rawValue)       "
        
        let command = commandFactory.createMudCommand(from: inputString, session: MockSession())
        
        guard let openDoorCommand = command as? OpenDoorCommand else {
            XCTFail("Expected an OpenDoorCommand instance, but got \(command).")
            return
        }
        
        XCTAssertEqual(openDoorCommand.direction, direction)
    }
    
    func test_SayCommand_create() {
        let sentence = "Hello, World!"
        let inputString = "  say  \(sentence)       "
        
        let command = commandFactory.createMudCommand(from: inputString, session: MockSession())
        
        guard let sayCommand = command as? SayCommand else {
            XCTFail("Expected an SayCommand instance, but got \(command).")
            return
        }
        
        XCTAssertEqual(sayCommand.sentence, sentence)
    }

    func test_SayCommand_withSingleWord() {
        let sentence = "Hello"
        let inputString = "  say  \(sentence)       "
        
        let command = commandFactory.createMudCommand(from: inputString, session: MockSession())
        
        guard let sayCommand = command as? SayCommand else {
            XCTFail("Expected an SayCommand instance, but got \(command).")
            return
        }
        
        XCTAssertEqual(sayCommand.sentence, sentence)
    }
    
    func test_WhisperCommand_create() {
        let message = "Hello, World!"
        let targetPlayerName = "testuser"
        let inputString = "  whisper     \(targetPlayerName)    \(message)       "
        
        let command = commandFactory.createMudCommand(from: inputString, session: MockSession())
        
        guard let whisperCommand = command as? WhisperCommand else {
            XCTFail("Expected an WhisperCommand instance, but got \(command).")
            return
        }
        
        XCTAssertEqual(whisperCommand.targetPlayerName, targetPlayerName)
        XCTAssertEqual(whisperCommand.message, message)
    }

    func test_WhisperCommand_withSingleWord() {
        let message = "Hello"
        let targetPlayerName = "testuser"
        let inputString = "  whisper     \(targetPlayerName)    \(message)       "
        
        let command = commandFactory.createMudCommand(from: inputString, session: MockSession())
        
        guard let whisperCommand = command as? WhisperCommand else {
            XCTFail("Expected an WhisperCommand instance, but got \(command).")
            return
        }
        
        XCTAssertEqual(whisperCommand.targetPlayerName, targetPlayerName)
        XCTAssertEqual(whisperCommand.message, message)
    }
}
