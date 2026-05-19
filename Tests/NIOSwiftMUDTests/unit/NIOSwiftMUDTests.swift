import XCTest
import class Foundation.Bundle
@testable import NIOSwiftMUD

final class NIOSwiftMUDTests: XCTestCase {
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
