import Testing
import NIO
import NIOSSH
import Foundation
@testable import NIOSwiftMUD

// SessionHandler writes SSHChannelData outbound, so we work with EmbeddedChannel
// directly rather than the ByteBuffer-based NIOPipelineTestHarness.
// Serialized because tests share the global SessionStorage via EmbeddedChannel remoteAddress.
@Suite(.serialized)
struct PipelineTests {
    init() {
        User.persist = false
        Room.persist = false
        Door.persist = false
    }

    @Test func connectReceivesWelcomeMessage() throws {
        let channel = try makeConnectedChannel(port: 0)
        defer { _ = try? channel.finish(acceptAlreadyClosed: true) }

        #expect(try collectOutbound(from: channel).joined().contains("Welcome to NIOSwiftMUD!"))
    }

    // ParseHandler runs command execution in a Swift Task. After writing input and
    // draining the sync handlers, we yield once to let the Task complete, then
    // drain the embedded event loop again so the response reaches the outbound buffer.
    @Test func typingHelpReceivesHelpText() async throws {
        let channel = try makeConnectedChannel(port: 0)
        defer { _ = try? channel.finish(acceptAlreadyClosed: true) }
        _ = try channel.readOutbound(as: SSHChannelData.self) // discard welcome

        try sendLine("HELP", to: channel)
        for _ in 0..<10 { await Task.yield() }
        channel.embeddedEventLoop.run()

        #expect(try collectOutbound(from: channel).contains { $0.contains("RECOGNIZED COMMANDS") })
    }

    // Two channels, different ports (= different remoteAddress) so SessionHandler
    // can distinguish them. Listener's session is pre-injected so SayCommand can
    // find it in SessionStorage and ResponseHandler can write to channel2.
    @Test func listenerReceivesSayMessage() async throws {
        let speaker = await makeUser()
        let listener = await makeUser()

        let channel1 = try makeConnectedChannel(port: 1)
        let channel2 = try makeConnectedChannel(port: 2)
        defer {
            _ = try? channel1.finish(acceptAlreadyClosed: true)
            _ = try? channel2.finish(acceptAlreadyClosed: true)
        }
        _ = try channel1.readOutbound(as: SSHChannelData.self) // discard welcome
        _ = try channel2.readOutbound(as: SSHChannelData.self) // discard welcome

        injectSession(user: speaker, channel: channel1)
        injectSession(user: listener, channel: channel2)

        try sendLine("SAY Hello", to: channel1)
        // SayCommand makes actor hops into AwesomeDB (User.find, User.filter);
        // Task.yield() is insufficient — a real sleep is needed.
        try await Task.sleep(nanoseconds: 100_000_000)
        channel1.embeddedEventLoop.run()
        channel2.embeddedEventLoop.run()

        #expect(try collectOutbound(from: channel2).contains { $0.contains("\(speaker.username) says: Hello") })
    }
}

// MARK: - Helpers

private func makeConnectedChannel(port: Int) throws -> EmbeddedChannel {
    let channel = EmbeddedChannel()
    try configureMUDPipeline(channel)
    try channel.connect(to: .init(ipAddress: "127.0.0.1", port: port)).wait()
    return channel
}

private func sendLine(_ text: String, to channel: EmbeddedChannel) throws {
    for char in text + "\n" {
        var buf = channel.allocator.buffer(capacity: 1)
        buf.writeString(String(char))
        try channel.writeInbound(SSHChannelData(byteBuffer: buf))
    }
    channel.embeddedEventLoop.run()
}

private func collectOutbound(from channel: EmbeddedChannel) throws -> [String] {
    var results: [String] = []
    while let out = try channel.readOutbound(as: SSHChannelData.self) {
        guard case .byteBuffer(var buf) = out.data,
              let text = buf.readString(length: buf.readableBytes) else { continue }
        results.append(text)
    }
    return results
}

private func injectSession(user: User, channel: EmbeddedChannel) {
    SessionStorage.replaceOrStoreSessionSync(
        MudSession(id: UUID(), channel: channel, playerID: user.id, shouldClose: false, currentString: "")
    )
}

private func makeUser() async -> User {
    var user = User(username: "user_\(UUID())", password: "pass")
    user.currentRoomID = Room.STARTER_ROOM_ID
    await user.save()
    return user
}
