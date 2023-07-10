@testable import Effector
import XCTest

final class AttachTests: XCTestCase {
    func testAttachEffect() async throws {
        let store = Store(10)
        let inc = Effect<Int, Int, Error> { $0 + 1 }
        
        let fx = attach(
            store: store,
            map: { s, p in s + p },
            effect: inc
        )
        
        let got = try await fx(1)
        
        sleep(1)
        
        XCTAssertEqual(got, 12)
    }
    
    func testAttachEffectFn() async throws {
        let store = Store(10)
        
        let fx: Effect<Int, Int, Error> = attach(
            store: store,
            effect: { s, p in s + p }
        )
        
        let got = try await fx(1)
        
        sleep(1)
        
        XCTAssertEqual(got, 11)
    }
}
