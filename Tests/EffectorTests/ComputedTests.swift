@testable import Effector
import XCTest

final class ComputedTests: XCTestCase {
    func testComputed() async throws {
        let entry = Event<Int>()
        let a = Store(1).on(entry) { _, v in v }
        let b = a.map { $0 + 1 }
        let c = a.map { $0 + 1 }
        let d = combine(b, c) { $0 + $1 }
        let e = d.map { $0 + 1 }
        let f = combine(d, e) { $0 + $1 }
        let g = combine(d, e) { $0 + $1 }
        let h = combine(f, g) { $0 + $1 }

        entry(1)

        XCTAssertEqual(h.getState(), 18)
    }
}
