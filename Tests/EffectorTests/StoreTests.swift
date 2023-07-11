@testable import Effector
import XCTest

final class StoreTests: XCTestCase {
    func testStoreSetState() async throws {
        let store = Store<Int>(0)

        store.setState(1)

        XCTAssertEqual(store.getState(), 1)
    }

    func testStoreNot() async throws {
        let store = Store(false)
        let inverted = store.not()

        XCTAssertEqual(inverted.getState(), true)

        store.setState(true)

        XCTAssertEqual(inverted.getState(), false)
    }

    func testStoreOn() async throws {
        let inc = Event<Void>()
        let reset = Event<Void>()

        let store = Store<Int>(0)
        var log: [Int] = []

        store.on(inc) { state, _ in
            state + 1
        }
        .reset(reset)

        store.watch { log.append($0) }

        inc()
        inc()
        inc()

        XCTAssertEqual(log, [0, 1, 2, 3])
        XCTAssertEqual(store.getState(), 3)

        reset()

        XCTAssertEqual(0, store.getState())
    }

    func testStoreMap() async throws {
        let store = Store(1)
        let inc = Event<Void>()

        let mapped = store.map { $0 + 1 }

        XCTAssertEqual(store.getState(), 1)
        XCTAssertEqual(mapped.getState(), 2)

        store.on(inc) { n, _ in n + 1 }

        inc()

        XCTAssertEqual(store.getState(), 2)
        XCTAssertEqual(mapped.getState(), 3)
    }

    func testStoreDefaultState() async throws {
        let store = Store(1)
        let inc = Event<Void>()

        store.on(inc) { state, _ in
            state + 1
        }

        inc()

        XCTAssertEqual(store.getState(), 2)
        XCTAssertEqual(store.defaultState, 1)
    }

    func testStoreUpdates() async throws {
        var log: [Int] = []
        let store = Store(1)
        let inc = Event<Void>()

        store.on(inc) { state, _ in
            state + 1
        }

        store.updates.watch { log.append($0) }

        inc()

        XCTAssertEqual(log, [2])
    }

    func testStoreEraseShareTheSameNode() async throws {
        let store = Store(0)
        let erased: Store<Int> = store.cast()

        XCTAssertEqual(ObjectIdentifier(store.graphite), ObjectIdentifier(erased.graphite))
    }

    func testStoreErase() async throws {
        let store = Store(0)
        let erased: Store<Int> = store.cast()

        let event = Event<Int>()

        store.on(event) { _, value in value }

        event(1)

        XCTAssertEqual(erased.getState(), 1)
    }
    
    
}
