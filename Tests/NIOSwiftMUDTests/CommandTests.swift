//
//  CommandTests.swift
//  
//
//  Created by Maarten Engels on 20/05/2023.
//

import Foundation
import XCTest
@testable import NIOSwiftMUD

class CommandTests: XCTestCase {
    
    struct MockSession: Session {
        let id: UUID
        var playerID: UUID?
        var shouldClose = false
        var currentString = ""
        
        init() {
            self.id = UUID()
        }
    }
    
    func test_HelpCommand() async {
        let session = MockSession()
        let command = HelpCommand(session: session)
        
        let result = await command.execute()
        
        XCTAssertEqual(result.first?.session.id, session.id)
        XCTAssertEqual(result.first?.message, HelpCommand.HELP_STRING)
    }
    
    func test_CloseCommand() async {
        let session = MockSession()
        let command = CloseCommand(session: session)
        
        XCTAssertFalse(session.shouldClose)
        
        let result = await command.execute()
        
        XCTAssertTrue(result.first?.session.shouldClose ?? false)
    }
    
    func test_CreateUserCommand() async {
        User.persist = false
        let session = MockSession()
        
        let testusername = "Testuser_\(UUID())"
        let command = CreateUserCommand(session: session, username: testusername, password: "password")
        
        let existingUser = await User.first(username: testusername)
        XCTAssertNil(existingUser)
        
        let result = await command.execute()
        
        guard result.count > 0 else {
            XCTFail("Expected at least 1 MudResponse.")
            return
        }
        
        XCTAssertEqual(result[0].session.id, session.id)
        
        guard let existingUserAfterSave = await User.first(username: testusername) else {
            XCTFail("Should have found recently created testuser: \(testusername)")
            return
        }
        
        XCTAssertEqual(result[0].session.playerID, existingUserAfterSave.id)
        XCTAssertEqual(result[0].message, "Welcome, \(testusername)!")
    }
    
    func test_CreateUserCommand_fails_withExistingUsername() async {
        User.persist = false
        let session = MockSession()
        
        let testusername = "Testuser_\(UUID())"
        
        let testuser = User(username: testusername, password: "password")
        await testuser.save()
        
        let command = CreateUserCommand(session: session, username: testusername, password: "123456")
        
        let result = await command.execute()
        
        guard result.count > 0 else {
            XCTFail("Expected at least 1 MudResponse.")
            return
        }
        
        XCTAssertEqual(result[0].session.id, session.id)
        XCTAssertNil(result[0].session.playerID)
        XCTAssertEqual(result[0].message, "Error creating user: usernameAlreadyTaken")
    }
    
    func test_LoginUserCommand() async {
        User.persist = false
        let session = MockSession()
        
        let testusername = "Testuser_\(UUID())"
        let testPassword = "FooBar123"
        let testuser = User(username: testusername, password: testPassword)
        await testuser.save()
        
        let command = LoginCommand(session: session, username: testusername, password: testPassword)
        
        let result = await command.execute()
        
        guard result.count > 0 else {
            XCTFail("Expected at least 1 MudResponse.")
            return
        }
        
        XCTAssertEqual(result[0].session.id, session.id)
        XCTAssertEqual(result[0].session.playerID, testuser.id)
        XCTAssertEqual(result[0].message, "Welcome back, \(testusername)!")
    }
    
    func test_LoginUserCommand_fails_withWrongPassword() async {
        User.persist = false
        let session = MockSession()
        
        let testusername = "Testuser_\(UUID())"
        let testPassword = "FooBar123"
        let testuser = User(username: testusername, password: testPassword)
        await testuser.save()
        
        let command = LoginCommand(session: session, username: testusername, password: "invalid"+testPassword)
        
        let result = await command.execute()
        
        guard result.count > 0 else {
            XCTFail("Expected at least 1 MudResponse.")
            return
        }
        
        XCTAssertEqual(result[0].session.id, session.id)
        XCTAssertNil(result[0].session.playerID)
        XCTAssertEqual(result[0].message, "Error logging in user: passwordMismatch")
    }
    
    func test_LookCommand() async {
        User.persist = false
        var session = MockSession()
        let testusername = "Testuser_\(UUID())"
        var testuser = User(username: testusername, password: "password")
        testuser.currentRoomID = Room.STARTER_ROOM_ID // Make sure the player is in the starter room.
        session.playerID = testuser.id // Simulate player successfully logged in.
        
        await testuser.save()
        
        let command = LookCommand(session: session)
        
        let result = await command.execute()
        
        guard result.count > 0 else {
            XCTFail("Expected at least 1 MudResponse.")
            return
        }
        
        guard let defaultRoom = await Room.find(Room.STARTER_ROOM_ID) else {
            XCTFail("Should have found a starter room.")
            return
        }
        
        let compareString = String(defaultRoom.name)
        let receivedString = String(result[0].message.prefix(compareString.count))
        XCTAssertEqual(receivedString, compareString)
    }
    
    func test_LookCommand_fails_whenNotLoggedIn() async {
        User.persist = false
        let session = MockSession()
        
        let command = LookCommand(session: session)
        
        let result = await command.execute()
        
        guard result.count > 0 else {
            XCTFail("Expected at least 1 MudResponse.")
            return
        }
        
        XCTAssertEqual(result[0].message, "Could not find player with id nil.")
    }
}
