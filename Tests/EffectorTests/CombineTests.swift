
@testable import Effector
import XCTest

// swiftlint:disable:next type_body_length
final class CombineTests: XCTestCase {
    func testCombine() async throws {
        let event = Event<Int>()

        let store1 = Store(1)

        store1.on(event) { _, n in n }

        let store2 = Store(2)
        let store3 = Store(0)

        let c = combine(store1, store2, store3) { $0 + $1 + $2 }

        XCTAssertEqual(c.getState(), 3)

        event(10)

        XCTAssertEqual(c.getState(), 12)
    }

    func testCombineBarrier() async throws {
        let store1 = Store(0)
        let derived1 = store1.map { $0 + 1 }
        let store2 = Store(10)
        let derived2 = store2.map { _ in 0 }
        let derived3 = store2.map { _ in 0 }
        let derived4 = store2.map { _ in 0 }

        let c = combine(store1, store2, derived1, derived2, derived3, derived4) { $0 + $1 + $2 + $3 + $4 + $5 }

        var updatesCount = 0
        var values = [Int]()

        c.watch { value in
            updatesCount += 1
            values.append(value)
        }

        XCTAssertEqual(c.getState(), 11) // 1 + 10 = 11
        XCTAssertEqual(updatesCount, 1)

        store1.setState(1)

        XCTAssertEqual(c.getState(), 13) // 1 + 2 + 10 = 13
        XCTAssertEqual(updatesCount, 2)

        store2.setState(20)

        XCTAssertEqual(c.getState(), 23) // 13 + 20 = 23
        XCTAssertEqual(updatesCount, 3)
        XCTAssertEqual(values, [11, 13, 23])
    }

    func testCombineNames() async throws {
        let storeA = Store(name: "a", 1)
        let storeB = Store(name: "b", 2)

        let c = combine(storeA, storeB) { $0 + $1 }

        XCTAssertEqual(c.name, "combine(a, b)")
    }

    func testCombineNamesDictionary() async throws {
        let storeA = Store<Any>(name: "a", 1)
        let storeB = Store<Any>(name: "b", 2)

        struct C: Decodable {
            let a: Int
            let b: Int
        }

        let c: Store<C> = combine([storeA, storeB])

        XCTAssertEqual(c.name, "combine(a, b)")
    }

    func testCombineAndSample() async throws {
        let a = Store(name: "a", 1)
        let b = Store(name: "b", 2)

        let c = combine(a, b) { $0 + $1 }

        let fx = Effect<Void, Void, Error>(name: "fx") {
            sleep(1)
        }

        b.on(fx.done) { _, _ in 0 }

        sample(
            trigger: fx.done,
            map: { _ in 10 },
            target: a
        )

        try await fx()

        XCTAssertEqual(c.getState(), 10)
    }
}
