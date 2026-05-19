import Testing
import NIO
@testable import NIOSwiftMUD

/// Single-client test harness for ByteBuffer-based NIO pipelines.
///
/// Example:
/// ```swift
/// let harness = try NIOPipelineTestHarness { channel in
///     try channel.pipeline.syncOperations.addHandlers([
///         ByteToMessageHandler(MyDecoder()),
///         MyLogicHandler(),
///         MessageToByteHandler(MyEncoder())
///     ])
/// }
/// let response = try harness.send(ByteBuffer(string: "hello\n"))
/// ```
public final class NIOPipelineTestHarness {
    private let channel: EmbeddedChannel

    public init(pipelineConfigurator: (Channel) throws -> Void) throws {
        self.channel = EmbeddedChannel()
        try pipelineConfigurator(channel)
        try channel.connect(to: .init(ipAddress: "127.0.0.1", port: 0)).wait()
    }

    /// Write a ByteBuffer into the inbound pipeline and return the first outbound ByteBuffer.
    public func send(_ input: ByteBuffer) throws -> ByteBuffer? {
        try channel.writeInbound(input)
        channel.embeddedEventLoop.run()
        return try channel.readOutbound(as: ByteBuffer.self)
    }

    /// Write a ByteBuffer and collect ALL ByteBuffers written to the outbound side.
    public func sendAndCollectAll(_ input: ByteBuffer) throws -> [ByteBuffer] {
        try channel.writeInbound(input)
        channel.embeddedEventLoop.run()
        var results: [ByteBuffer] = []
        while let buf = try channel.readOutbound(as: ByteBuffer.self) {
            results.append(buf)
        }
        return results
    }

    public func assertClean(file: StaticString = #file, line: UInt = #line) {
        do {
            _ = try channel.finish()
        } catch {
            Issue.record(error, "Pipeline not clean: \(error). File: \(file), Line: \(line)")
        }
    }

    deinit {
        _ = try? channel.finish(acceptAlreadyClosed: true)
    }
}

/// Multi-client test environment for broadcast pipelines.
///
/// All channels share a single `EmbeddedEventLoop`, so `loop.run()` drains
/// every cross-client task synchronously — fully deterministic, no sleeps needed.
final class NIOMultiClientTestEnvironment {
    let loop: EmbeddedEventLoop
    private var clients: [EmbeddedChannel] = []
    private let pipelineConfigurator: (Channel) throws -> Void

    init(loop: EmbeddedEventLoop, pipelineConfigurator: @escaping (Channel) throws -> Void) {
        self.loop = loop
        self.pipelineConfigurator = pipelineConfigurator
    }

    @discardableResult
    func connectClient() throws -> Int {
        let channel = EmbeddedChannel(loop: loop)
        try pipelineConfigurator(channel)
        try channel.connect(to: .init(ipAddress: "127.0.0.1", port: 0)).wait()
        loop.run()
        let index = clients.count
        clients.append(channel)
        return index
    }

    func send(_ buffer: ByteBuffer, from clientIndex: Int) throws {
        try clients[clientIndex].writeInbound(buffer)
        loop.run()
    }

    func receive(from clientIndex: Int) throws -> [String] {
        loop.run()
        var results: [String] = []
        while var buf = try clients[clientIndex].readOutbound(as: ByteBuffer.self) {
            if let str = buf.readString(length: buf.readableBytes) {
                results.append(str)
            }
        }
        return results
    }

    func finish() {
        for client in clients {
            _ = try? client.finish(acceptAlreadyClosed: true)
        }
    }
}
