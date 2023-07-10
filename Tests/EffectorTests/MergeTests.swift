@testable import Effector
import XCTest

final class MergeTests: XCTestCase {
    func testTwoEvents() async throws {
        let event1 = Event<Int>()
        let event2 = Event<Int>()
        let merged = merge(event1, event2)
        let store = Store<Int>(0)
        var log: [Int] = []
        
        merged.watch { log.append($0) }
        store.on(merged) { n, x in n + x }
        
        event1(1)
        event2(2)
        
        XCTAssertEqual(log, [1, 2])
        XCTAssertEqual(store.getState(), 3)
    }
}
