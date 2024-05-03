import XCTest
import class Foundation.Bundle
@testable import NIOSwiftMUD

final class NIOSwiftMUDTests: XCTestCase {
//    func testExample() throws {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct
//        // results.
//
//        // Some of the APIs that we use below are available in macOS 10.13 and above.
//        guard #available(macOS 10.13, *) else {
//            return
//        }
//
//        // Mac Catalyst won't have `Process`, but it is supported for executables.
//        #if !targetEnvironment(macCatalyst)
//
//        let fooBinary = productsDirectory.appendingPathComponent("NIOSwiftMUD")
//
//        let process = Process()
//        process.executableURL = fooBinary
//
//        let pipe = Pipe()
//        process.standardOutput = pipe
//
//        try process.run()
//        process.waitUntilExit()
//
//        let data = pipe.fileHandleForReading.readDataToEndOfFile()
//        let output = String(data: data, encoding: .utf8)
//
//        XCTAssertEqual(output, "Hello, world!\n")
//        #endif
//    }
//
//    /// Returns path to the built products directory.
//    var productsDirectory: URL {
//      #if os(macOS)
//        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
//            return bundle.bundleURL.deletingLastPathComponent()
//        }
//        fatalError("couldn't find the products directory")
//      #else
//        return Bundle.main.bundleURL
//      #endif
//    }

    func test_SessionStorage_isThreadSafe() {
        struct TestSession: Session { 
            let id: UUID
            var playerID: UUID?
            var shouldClose = false
            var currentString = ""
        }

        let group = DispatchGroup()
        let queue = DispatchQueue(label: "com.nioswiftmud.test", attributes: .concurrent)
        let count = 1000
        for _ in 0 ..< count {
            group.enter()
            queue.async {
                SessionStorage.replaceOrStoreSessionSync(TestSession(id: UUID()))
                group.leave()
            }
        }
        group.wait()

        // we can't do an equality comparison because other tests might also add sessions to Session Storage.
        // but we should have at least as much as count.
        XCTAssertGreaterThanOrEqual(SessionStorage.sessionCount(), count)
    }
}
