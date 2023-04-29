

@testable import Effector
import XCTest

final class StoreReinitTests: XCTestCase {
    func testReinit() {
        let event = Event<Void>()

        let store = Store(0)

        sample(trigger: event, target: store.reinit)

        store.setState(1)
        XCTAssertEqual(store.getState(), 1)

        event()

        XCTAssertEqual(store.getState(), 0)
    }
}
