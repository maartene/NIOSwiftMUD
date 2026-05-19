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
    let userRepository = InmemoryUserRepository()
    let roomRepository = RoomRepositoryStub()
    let doorRepository = DoorRepositoryStub()
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

        let testusername = userRepository.testUser.username

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
        #expect(result[0].session.playerID == userRepository.testUser.id)
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
    @Test func lookCommand() async {
        var session = MockSession()

        session.playerID = userRepository.testUser.id // Simulate player successfully logged in.

        let command = LookCommand(session: session)

        let result = await command.execute(in: world)

        guard result.count > 0 else {
            Issue.record("Expected at least 1 MudResponse.")
            return
        }

        guard let defaultRoom = await roomRepository.find(Room.STARTER_ROOM_ID) else {
            Issue.record("Should have found a starter room.")
            return
        }

        let compareString = String(defaultRoom.name)
        let receivedString = String(result[0].message.prefix(compareString.count))
        #expect(receivedString == compareString)
    }

    // MARK: GoCommand
    @Test func goCommand() async {
        let roomCount = await roomRepository.count()
        #expect(roomCount > 1)

        var session = MockSession()
        session.playerID = userRepository.testUser.id // Simulate player successfully logged in.

        guard let room = await roomRepository.find(userRepository.testUser.currentRoomID) else {
            Issue.record("Should have found a room for the player.")
            return
        }

        guard room.exits.count > 0 else {
            Issue.record("Should have found at least 1 exit in the room.")
            return
        }

        guard let firstExit = room.exits.first else {
            Issue.record("Should have found at least 1 exit in the room.")
            return
        }

        // Make sure the exit is passable, by opening any door if one exists.
        if var door = await Door.find(firstExit.doorID) {
            door.isOpen = true
            await door.save()
            print("Opened door \(door.id).")
        }

        let command = GoCommand(session: session, direction: room.exits[0].direction)

        let result = await command.execute(in: world)

        guard result.count > 0 else {
            Issue.record("Expected at least 1 MudResponse.")
            await Room.storage.reloadStorage()
            return
        }

        guard let updatedPlayer = await userRepository.find(session.playerID) else {
            Issue.record("Player should have been found.")
            return
        }
        #expect(updatedPlayer.currentRoomID == room.exits[0].targetRoomID)
    }

    @Test func `go command fails if door is closed`() async throws {
        var session = MockSession()
        let currentRoomID = UUID(uuidString: "E9AFECD5-4E81-453A-84F3-E709D3E908F2")!
        let testuser = User(username: "a user", password: "password", currentRoomID: currentRoomID)
        session.playerID = testuser.id // Simulate player successfully logged in.
        
        await userRepository.save(testuser)

        let command = GoCommand(session: session, direction: .East)

        let result = await command.execute(in: world)

        guard result.count > 0 else {
            Issue.record("Expected at least 1 MudResponse.")
            await Room.storage.reloadStorage()
            return
        }

        let updatedPlayer = try #require(await userRepository.find(session.playerID), "Player should have been found.")

        #expect(result[0].message == "The exit is impassable.")
        #expect(updatedPlayer.currentRoomID == currentRoomID)
    }

    @Test func `go command fails if there is no exit in direction`() async throws {
        var session = MockSession()
        let currentRoomID = UUID(uuidString: "E9AFECD5-4E81-453A-84F3-E709D3E908F2")!
        let testuser = User(username: "a user", password: "password", currentRoomID: currentRoomID)
        session.playerID = testuser.id // Simulate player successfully logged in.
        await userRepository.save(testuser)

        let command = GoCommand(session: session, direction: .North)

        let result = await command.execute(in: world)
        try #require(result.isEmpty == false, "Expected at least 1 MudResponse.")

        let updatedPlayer = try #require(await userRepository.find(session.playerID), "Player should have been found.")
        #expect(result[0].message == "No exit found in direction \(command.direction).")
        #expect(updatedPlayer.currentRoomID == currentRoomID)
    }

    // MARK: OpenDoorCommand
    @Test func openDoor() async {
        let closedDoor = Door(id: UUID(), isOpen: false)
        await closedDoor.save()

        let room1ID = UUID()
        let room2ID = UUID()

        let room1 = Room(id: room1ID, name: "Room 1", description: "Room 1", exits: [Exit(direction: .North, targetRoomID: room2ID, doorID: closedDoor.id)])
        let room2 = Room(id: room2ID, name: "Room 2", description: "Room 2", exits: [Exit(direction: .South, targetRoomID: room1ID, doorID: closedDoor.id)])

        await room1.save()
        await room2.save()

        var session = MockSession()
        let testusername = "Testuser_\(UUID())"
        var testuser = User(username: testusername, password: "password")
        testuser.currentRoomID = room1ID
        session.playerID = testuser.id // Simulate player successfully logged in.

        await testuser.save()

        let command = OpenDoorCommand(session: session, direction: .North)

        let result = await command.execute()

        guard result.count > 0 else {
            Issue.record("Expected at least 1 MudResponse.")
            return
        }

        guard let updatedDoor = await Door.find(closedDoor.id) else {
            Issue.record("Door should have been found.")
            return
        }

        #expect(updatedDoor.isOpen)
    }

    @Test func openDoorFailsIfDoorIsAlreadyOpen() async {
        let openDoor = Door(id: UUID(), isOpen: true)
        await openDoor.save()

        let room1ID = UUID()
        let room2ID = UUID()

        let room1 = Room(id: room1ID, name: "Room 1", description: "Room 1", exits: [Exit(direction: .North, targetRoomID: room2ID, doorID: openDoor.id)])
        let room2 = Room(id: room2ID, name: "Room 2", description: "Room 2", exits: [Exit(direction: .South, targetRoomID: room1ID, doorID: openDoor.id)])

        await room1.save()
        await room2.save()

        var session = MockSession()
        let testusername = "Testuser_\(UUID())"
        var testuser = User(username: testusername, password: "password")
        testuser.currentRoomID = room1ID
        session.playerID = testuser.id // Simulate player successfully logged in.

        await testuser.save()

        let command = OpenDoorCommand(session: session, direction: .North)

        let result = await command.execute()

        guard result.count > 0 else {
            Issue.record("Expected at least 1 MudResponse.")
            return
        }

        #expect(result[0].message == "Door in direction \(command.direction) is already open.")
    }

    // MARK: SayCommand
    @Test func sayCommand() async {
        var session = MockSession()
        let testusername = "Testuser_\(UUID())"
        var testuser = User(username: testusername, password: "password")
        testuser.currentRoomID = Room.STARTER_ROOM_ID
        session.playerID = testuser.id // Simulate player successfully logged in.
        await testuser.save()

        var session2 = MockSession()
        var testuser2 = User(username: "testuser_\(UUID())", password: "String")
        testuser2.currentRoomID = Room.STARTER_ROOM_ID
        session2.playerID = testuser2.id
        SessionStorage.replaceOrStoreSessionSync(session2)
        await testuser2.save()

        let command = SayCommand(session: session, sentence: "Hello World!")

        let result = await command.execute()

        guard result.count > 1 else {
            Issue.record("Expected at least 2 MudResponses.")
            return
        }

        #expect(result[0].message == "You say: \(command.sentence)")
        #expect(result[1].message == "\(testusername) says: \(command.sentence)")
    }

    // MARK: WhisperCommand
    @Test func whisperCommand() async {
        // Lots of setup needed: create three users, including sessions

        // testuser1
        var session = MockSession()
        let testusername = "Testuser_\(UUID())"
        var testuser = User(username: testusername, password: "password")
        testuser.currentRoomID = Room.STARTER_ROOM_ID
        session.playerID = testuser.id // Simulate player successfully logged in.
        SessionStorage.replaceOrStoreSessionSync(session)
        await testuser.save()

        defer { SessionStorage.deleteSession(session) } // Let's make sure we cleanup the sessions we created.

        // testuser2
        var session2 = MockSession()
        let testusername2 = "Testuser2_\(UUID())"
        var testuser2 = User(username: testusername2, password: "String")
        testuser2.currentRoomID = Room.STARTER_ROOM_ID
        session2.playerID = testuser2.id
        session2.currentString = "testuser2"
        SessionStorage.replaceOrStoreSessionSync(session2)
        await testuser2.save()

        defer { SessionStorage.deleteSession(session2) } // Let's make sure we cleanup the sessions we created.

        // testuser3
        var session3 = MockSession()
        let testusername3 = "Testuser3_\(UUID())"
        var testuser3 = User(username: testusername3, password: "String")
        testuser3.currentRoomID = Room.STARTER_ROOM_ID
        session3.playerID = testuser3.id
        session3.currentString = "testuser3"
        SessionStorage.replaceOrStoreSessionSync(session3)
        await testuser3.save()

        defer { SessionStorage.deleteSession(session3) } // Let's make sure we cleanup the sessions we created.

        // the actual SUT
        let command = WhisperCommand(session: session, targetPlayerName: testusername3, message: "For your ears only")

        let result = await command.execute()

        // Validate the results
        guard result.count > 2 else {
            Issue.record("Expected at least 3 MudResponses.")
            return
        }

        #expect(result[0].message == "You whisper to \(testusername3): \(command.message)")

        guard let messageForTestUser2 = result.first(where: { $0.session.playerID == testuser2.id }) else {
            Issue.record("There should be a message for testuser2")
            return
        }

        guard let messageForTestUser3 = result.first(where: { $0.session.playerID == testuser3.id }) else {
            Issue.record("There should be a message for testuser3")
            return
        }

        #expect(messageForTestUser2.message == "\(testusername) whispers something to \(testuser3.username), but you can't quite make out what is said.")
        #expect(messageForTestUser3.message == "\(testusername) whispers to you: \(command.message)")
    }

    @Test func whisperCommandReturnsFunnyMessageWhenYouTargetYourself() async {
        var session = MockSession()
        let testusername = "Testuser_\(UUID())"
        var testuser = User(username: testusername, password: "password")
        testuser.currentRoomID = Room.STARTER_ROOM_ID
        session.playerID = testuser.id // Simulate player successfully logged in.
        SessionStorage.replaceOrStoreSessionSync(session)
        await testuser.save()

        defer { SessionStorage.deleteSession(session) } // Let's make sure we cleanup the sessions we created.

        // the actual SUT
        let command = WhisperCommand(session: session, targetPlayerName: testusername, message: "For your ears only")

        let result = await command.execute()

        // Validate the results
        #expect(result.count == 1)
        #expect(result[0].message == "Talking to yourself much, eh?")
    }
}

struct RoomRepositoryStub: Repository<Room> {
    private let rooms = [
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
    ]
    
    func find(_ id: UUID?) async -> Room? {
        return rooms.first(where: { $0.id == id })
    }
    
    func count() async -> Int {
        rooms.count
    }
    
    func save(_ object: Room) async {
        // no-op
    }
}

final class InmemoryUserRepository: UserRepository {
    private var users = [
        User(id: UUID(), username: "test_user", password: "password", currentRoomID: Room.STARTER_ROOM_ID)
    ]
    
    var testUser: User {
        users[0]
    }
    
    func find(_ id: UUID?) async -> NIOSwiftMUD.User? {
        return users.first(where: { $0.id == id })
    }
    
    func count() async -> Int {
        users.count
    }
    
    func save(_ user: User) async {
        if let existingIndex = users.firstIndex(where: { user.id == $0.id   }) {
            users[existingIndex] = user
        } else {
            users.append(user)
        }
    }
    
    func find(_ username: String) async -> User? {
        users.first { $0.username == username }
    }
}


struct DoorRepositoryStub: Repository<Door> {
    let doors = [
        Door(id: UUID(uuidString: "41D5047C-2DC0-42D0-B1F7-3A2B241B3F23")!, isOpen: false)
    ]
    
    func find(_ id: UUID?) async -> Door? {
        doors.first(where: { $0.id == id })
    }
    
    func count() async -> Int {
        1
    }
    
    func save(_ object: NIOSwiftMUD.Door) async {
        // no-op
    }
}
