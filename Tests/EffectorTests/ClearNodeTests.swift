

@testable import Effector
import XCTest

final class ClearNodeTests: XCTestCase {
    func testEvent() {
        var called = false
        let event = Event<Void>()

        event.watch { called = true }

        clear(event)

        event()

        XCTAssertFalse(called)
    }

    func testStore() {
        var calledTimes = 0
        let store = Store(0)

        store.watch { _ in calledTimes += 1 }

        clear(store)

        store.setState(1)

        XCTAssertEqual(calledTimes, 1)
    }

    func testWillNotBrokeSubscribers() {
        var calledTimes = 0

        let eventA = Event<Int>()
        let eventB = Event<Int>()
        eventB.watch { _ in calledTimes += 1 }

        forward(from: eventA, to: eventB)

        eventA(0)
        XCTAssertEqual(calledTimes, 1)

        clear(eventA)

        eventA(1) // nothing happens
        XCTAssertEqual(calledTimes, 1)
        eventB(2) // work as expected
        XCTAssertEqual(calledTimes, 2)
    }
}
