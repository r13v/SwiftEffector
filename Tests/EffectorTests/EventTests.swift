@testable import Effector
import XCTest

final class EventTests: XCTestCase {
    func testWatch() async throws {
        let event = Event<Int>()

        var log: [Int] = []

        event.watch { int in
            log.append(int)
        }

        event(10)

        XCTAssertEqual([10], log)
    }

    func testWatchUnsubscribe() async throws {
        let event = Event<Int>()

        var log: [Int] = []

        let unsubscribe = event.watch { int in
            log.append(int)
        }

        event(10)

        unsubscribe()

        event(20)
        event(30)

        XCTAssertEqual([10], log)
    }

    func testMap() async throws {
        let event = Event<Int>()
        let mapped = event.map { $0 + 1 }
        var log: [Int] = []
        mapped.watch { log.append($0) }

        event(1)

        XCTAssertEqual([2], log)
    }

    func testPrepend() async throws {
        let event = Event<Int>()
        var log: [Int] = []
        event.watch { log.append($0) }
        let before: Event<Int> = event.prepend { $0 + 1 }

        before(1)

        XCTAssertEqual([2], log)
    }

    func testFilter() async throws {
        let event = Event<Int>()
        let filtered = event.filter { $0 > 0 }
        var log: [Int] = []
        filtered.watch { log.append($0) }

        event(1)
        event(-1)
        event(2)

        XCTAssertEqual([1, 2], log)
    }

    func testFilterMap() async throws {
        let event = Event<Int>()
        let filtered: Event<Int> = event.filterMap { n in
            if n < 0 {
                return nil
            }

            return n + 10
        }
        var log: [Int] = []

        filtered.watch { log.append($0) }

        event(1)
        event(-1)
        event(10)

        XCTAssertEqual([11, 20], log)
    }

    func testErase() async throws {
        let event = Event<Int>()

        let erased: AnyEvent = event.erase()

        XCTAssertEqual(ObjectIdentifier(event.graphite), ObjectIdentifier(erased.graphite))
    }
}
