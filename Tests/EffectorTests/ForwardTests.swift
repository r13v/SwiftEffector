@testable import Effector
import XCTest

final class ForwardTests: XCTestCase {
    func testEventToStore() async throws {
        let event = Event<Int>()
        let store = Store<Int>(0)
        var log: [Int] = []
        store.watch { log.append($0) }
        forward(from: [event], to: [store])
        
        event(1)
        event(2)
        
        XCTAssertEqual(log, [0, 1, 2])
        XCTAssertEqual(store.getState(), 2)
    }
}
