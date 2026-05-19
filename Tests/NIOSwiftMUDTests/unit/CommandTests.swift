//
//  CommandTests.swift
//  
//
//  Created by Maarten Engels on 20/05/2023.
//

import Foundation
import Testing
@testable import NIOSwiftMUD

@Suite struct CommandTests {
    let userRepository = InMemoryRepository(storage: [User(id: UUID(), username: "test_user", password: "password", currentRoomID: Room.STARTER_ROOM_ID),
                                                      User(id: UUID(), username: "a user", password: "123456", currentRoomID: UUID(uuidString: "E9AFECD5-4E81-453A-84F3-E709D3E908F2")!),])
    let roomRepository = InMemoryRepository(storage: [
        Room(id: Room.STARTER_ROOM_ID, name: "Starter room", description: "Nothing interesting here", exits: [
            Exit(direction: .North, targetRoomID: UUID(uuidString: "21C9D03A-ADEA-4120-A126-406C1D841BED")!, doorID: nil)
        ]),
        Room(id: UUID(uuidString: "21C9D03A-ADEA-4120-A126-406C1D841BED")!, name: "The second room", description: "Nothing here either", exits: [
            Exit(direction: .South, targetRoomID: Room.STARTER_ROOM_ID, doorID: nil)
        ]),
        Room(id: UUID(uuidString: "E9AFECD5-4E81-453A-84F3-E709D3E908F2")!, name: "The second room", description: "Nothing here either", exits: [
            Exit(direction: .East, targetRoomID: UUID(uuidString: "D53009EE-A0DE-4AB1-87A0-CD8C0BFD56FD")!, doorID: UUID(uuidString: "41D5047C-2DC0-42D0-B1F7-3A2B241B3F23")!)
        ]),
        Room(id: UUID(uuidString: "D53009EE-A0DE-4AB1-87A0-CD8C0BFD56FD")!, name: "The second room", description: "Nothing here either", exits: [
            Exit(direction: .West, targetRoomID: UUID(uuidString: "E9AFECD5-4E81-453A-84F3-E709D3E908F2")!, doorID: UUID(uuidString: "41D5047C-2DC0-42D0-B1F7-3A2B241B3F23")!)
        ]),
    ])
    let doorRepository = InMemoryRepository(storage: [Door(id: UUID(uuidString: "41D5047C-2DC0-42D0-B1F7-3A2B241B3F23")!, isOpen: false)])
    let world: World
    
    init() {
        world = World(roomRepository: roomRepository, userRepository: userRepository, doorRepository: doorRepository)
    }
    
    // MARK: Helpders
    struct MockSession: Session {
        let id: UUID
        var playerID: UUID?
        var shouldClose = false
        var currentString = ""
        
        init() {
            self.id = UUID()
        }
    }

    // MARK: Generic Tests
    @Test func `commands that require login fail when not logged in`() async throws {
        let session = MockSession()
        let commandsThatRequireLogin = MudCommandFactory().allCommands.filter { $0.requiresLogin }

        for commandType in commandsThatRequireLogin {
            let arguments = Array(repeating: "north", count: commandType.expectedArgumentCount)
            let command = commandType.create(arguments, session: session)

            let result = try #require(await command?.execute(in: world), "Command \(commandType) should not be nil.")

            guard result.count > 0 else {
                Issue.record("Expected at least 1 MudResponse.")
                return
            }

            #expect(result[0].message == command?.couldNotFindPlayerMessage)
        }
    }
    
    // MARK: HelpCommand
    @Test func helpCommand() async {
        let session = MockSession()
        let command = HelpCommand(session: session)
        
        let result = await command.execute(in: world)
        
        #expect(result.first?.session.id == session.id)
        #expect(result.first?.message == HelpCommand.HELP_STRING)
    }
    
    // MARK: CloseCommand
    @Test func closeCommand() async {
        let session = MockSession()
        let command = CloseCommand(session: session)
        
        #expect(session.shouldClose == false)
        
        let result = await command.execute(in: world)
        
        #expect(result.first?.session.shouldClose ?? false)
    }
    
    // MARK: CreateUserCommand
    @Test func createUserCommand() async throws {
        let session = MockSession()
        
        let testusername = "Testuser_\(UUID())"
        let command = CreateUserCommand(session: session, username: testusername, password: "password")
        
        try #require(await User.first(username: testusername) == nil)
        
        let result = await command.execute(in: world)
        
        try #require (result.count > 0)
        
        #expect(result[0].session.id == session.id)
        
        let existingUserAfterSave = try #require(await User.first(username: testusername), "Should have found recently created testuser: \(testusername)")
        
        #expect(result[0].session.playerID == existingUserAfterSave.id)
        #expect(result[0].message == "Welcome, \(testusername)!")
    }
    
    @Test func `create user command fails with existing username`() async {
        let session = MockSession()

        let testusername = userRepository.userInStartingRoom.username

        let command = CreateUserCommand(session: session, username: testusername, password: "123456")

        let result = await command.execute(in: world)

        guard result.count > 0 else {
            Issue.record("Expected at least 1 MudResponse.")
            return
        }

        #expect(result[0].session.id == session.id)
        #expect(result[0].session.playerID == nil)
        #expect(result[0].message == "Error creating user: usernameAlreadyTaken")
    }

    // MARK: LoginUserCommand
    @Test func loginUserCommand() async {
        let session = MockSession()

        let command = LoginCommand(session: session, username: "test_user", password: "password")

        let result = await command.execute(in: world)

        guard result.count > 0 else {
            Issue.record("Expected at least 1 MudResponse.")
            return
        }

        #expect(result[0].session.id == session.id)
        #expect(result[0].session.playerID == userRepository.userInStartingRoom.id)
        #expect(result[0].message == "Welcome back, test_user!")
    }

    @Test func loginUserCommandFailsWithWrongPassword() async {
        let session = MockSession()

        let command = LoginCommand(session: session, username: "test_user", password: "invalid password")

        let result = await command.execute(in: world)

        guard result.count > 0 else {
            Issue.record("Expected at least 1 MudResponse.")
            return
        }

        #expect(result[0].session.id == session.id)
        #expect(result[0].session.playerID == nil)
        #expect(result[0].message == "Error logging in user: passwordMismatch")
    }

    // MARK: LookCommand
    @Test func lookCommand() async throws {
        var session = MockSession()
        session.playerID = userRepository.userInStartingRoom.id // Simulate player successfully logged in.

        let command = LookCommand(session: session)
        
        let result = await command.execute(in: world)

        try #require(result.isEmpty == false, "Expected at least 1 MudResponse.")
        
        let defaultRoom = try #require(await roomRepository.find(Room.STARTER_ROOM_ID), "Should have found a starter room.")

        let compareString = String(defaultRoom.name)
        let receivedString = String(result[0].message.prefix(compareString.count))
        #expect(receivedString == compareString)
    }

    // MARK: GoCommand
    @Test func goCommand() async throws {
        let roomCount = await roomRepository.count()
        #expect(roomCount > 1)

        var session = MockSession()
        session.playerID = userRepository.userInStartingRoom.id // Simulate player successfully logged in.

        let room = try #require(await roomRepository.find(userRepository.userInStartingRoom.currentRoomID), "Should have found a room for the player.")

        try #require(room.exits.isEmpty == false, "Should have found at least 1 exit in the room.")
        
        let firstExit = try #require(room.exits.first, "Should have found at least 1 exit in the room.")

        let command = GoCommand(session: session, direction: room.exits[0].direction)

        let result = await command.execute(in: world)

        try #require(result.isEmpty == false)

        let updatedPlayer = try #require(await userRepository.find(session.playerID), "Player should have been found.")

        #expect(updatedPlayer.currentRoomID == room.exits[0].targetRoomID)
    }

    @Test func `go command fails if door is closed`() async throws {
        var session = MockSession()
        session.playerID = userRepository.userNearClosedDoor.id
        let currentRoomID = userRepository.userNearClosedDoor.currentRoomID
        
        let command = GoCommand(session: session, direction: .East)

        let result = await command.execute(in: world)

        try #require(result.isEmpty == false, "Expected at least 1 MudResponse.")

        let updatedPlayer = try #require(await userRepository.find(session.playerID), "Player should have been found.")

        #expect(result[0].message == "The exit is impassable.")
        #expect(updatedPlayer.currentRoomID == currentRoomID)
    }

    @Test func `go command fails if there is no exit in direction`() async throws {
        var session = MockSession()
        let currentRoomID = userRepository.userNearClosedDoor.currentRoomID
        session.playerID = userRepository.userNearClosedDoor.id

        let command = GoCommand(session: session, direction: .North)

        let result = await command.execute(in: world)
        try #require(result.isEmpty == false, "Expected at least 1 MudResponse.")

        let updatedPlayer = try #require(await userRepository.find(session.playerID), "Player should have been found.")
        #expect(result[0].message == "No exit found in direction \(command.direction).")
        #expect(updatedPlayer.currentRoomID == currentRoomID)
    }

    // MARK: OpenDoorCommand
    @Test func openDoor() async throws {
        var session = MockSession()
        session.playerID = userRepository.userNearClosedDoor.id
        
        let command = OpenDoorCommand(session: session, direction: .East)

        let result = await command.execute(in: world)

        try #require(result.isEmpty == false, "Expected at least 1 MudResponse.")

        #expect(doorRepository.closedDoor.isOpen)
    }

    @Test func openDoorFailsIfDoorIsAlreadyOpen() async throws {
        var openDoor = doorRepository.closedDoor
        openDoor.isOpen = true
        await doorRepository.save(openDoor)

        var session = MockSession()
        session.playerID = userRepository.userNearClosedDoor.id

        let command = OpenDoorCommand(session: session, direction: .East)

        let result = await command.execute(in: world)

        try #require(result.isEmpty == false, "Expected at least 1 MudResponse.")

        #expect(result[0].message == "Door in direction \(command.direction) is already open.")
    }

    // MARK: SayCommand
    @Test func sayCommand() async throws {
        var session = MockSession()
        let testusername = "Testuser_\(UUID())"
        var testuser = User(username: testusername, password: "password")
        testuser.currentRoomID = Room.STARTER_ROOM_ID
        session.playerID = testuser.id // Simulate player successfully logged in.
        await userRepository.save(testuser)

        var session2 = MockSession()
        var testuser2 = User(username: "testuser_\(UUID())", password: "String")
        testuser2.currentRoomID = Room.STARTER_ROOM_ID
        session2.playerID = testuser2.id
        SessionStorage.replaceOrStoreSessionSync(session2)
        await userRepository.save(testuser2)

        let command = SayCommand(session: session, sentence: "Hello World!")

        let result = await command.execute(in: world)

        try #require(result.count > 1, "Expected at least 2 MudResponses.")

        #expect(result[0].message == "You say: \(command.sentence)")
        #expect(result[1].message == "\(testusername) says: \(command.sentence)")
    }

    // MARK: WhisperCommand
    @Test func whisperCommand() async throws {
        // Lots of setup needed: create three users, including sessions

        // testuser1
        var session = MockSession()
        let testusername = "Testuser_\(UUID())"
        var testuser = User(username: testusername, password: "password")
        testuser.currentRoomID = Room.STARTER_ROOM_ID
        session.playerID = testuser.id // Simulate player successfully logged in.
        SessionStorage.replaceOrStoreSessionSync(session)
        await userRepository.save(testuser)

        defer { SessionStorage.deleteSession(session) } // Let's make sure we cleanup the sessions we created.

        // testuser2
        var session2 = MockSession()
        let testusername2 = "Testuser2_\(UUID())"
        var testuser2 = User(username: testusername2, password: "String")
        testuser2.currentRoomID = Room.STARTER_ROOM_ID
        session2.playerID = testuser2.id
        session2.currentString = "testuser2"
        SessionStorage.replaceOrStoreSessionSync(session2)
        await userRepository.save(testuser2)

        defer { SessionStorage.deleteSession(session2) } // Let's make sure we cleanup the sessions we created.

        // testuser3
        var session3 = MockSession()
        let testusername3 = "Testuser3_\(UUID())"
        var testuser3 = User(username: testusername3, password: "String")
        testuser3.currentRoomID = Room.STARTER_ROOM_ID
        session3.playerID = testuser3.id
        session3.currentString = "testuser3"
        SessionStorage.replaceOrStoreSessionSync(session3)
        await userRepository.save(testuser3)

        defer { SessionStorage.deleteSession(session3) } // Let's make sure we cleanup the sessions we created.

        // the actual SUT
        let command = WhisperCommand(session: session, targetPlayerName: testusername3, message: "For your ears only")

        let result = await command.execute(in: world)

        // Validate the results
        try #require(result.count > 2, "Expected at least 3 MudResponses.")

        #expect(result[0].message == "You whisper to \(testusername3): \(command.message)")

        let messageForTestUser2 = try #require(result.first(where: { $0.session.playerID == testuser2.id }), "There should be a message for testuser2")

        let messageForTestUser3 = try #require(result.first(where: { $0.session.playerID == testuser3.id }), "There should be a message for testuser3")

        #expect(messageForTestUser2.message == "\(testusername) whispers something to \(testuser3.username), but you can't quite make out what is said.")
        #expect(messageForTestUser3.message == "\(testusername) whispers to you: \(command.message)")
    }

    @Test func whisperCommandReturnsFunnyMessageWhenYouTargetYourself() async {
        var session = MockSession()
        session.playerID = userRepository.userInStartingRoom.id

        // the actual SUT
        let command = WhisperCommand(session: session, targetPlayerName: "test_user", message: "For your ears only")

        let result = await command.execute(in: world)

        // Validate the results
        #expect(result.count == 1)
        #expect(result[0].message == "Talking to yourself much, eh?")
    }
}

final class InMemoryRepository<T: Identifiable>: Repository<T> {
    private var storage: [T] = []
    
    init(storage: [T]) {
        self.storage = storage
    }
    
    func find(_ id: T.ID?) async -> T? {
        storage.first(where: { $0.id == id })
    }
        
    func count() async -> Int {
        storage.count
    }
    
    func save(_ object: T) async {
        if let existingIndex = storage.firstIndex(where: { object.id == $0.id   }) {
            storage[existingIndex] = object
        } else {
            storage.append(object)
        }
    }
    
    func filter(where predicate: (T) -> Bool) async -> [T] {
        storage.filter(predicate)
    }
}

extension InMemoryRepository where T == Door {
    var closedDoor: Door {
        storage[0]
    }
}

extension InMemoryRepository where T == User {
    var userInStartingRoom: User {
        storage[0]
    }
    
    var userNearClosedDoor: User {
        storage[1]
    }
}
