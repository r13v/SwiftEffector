@testable import Effector
import XCTest

final class AttachTests: XCTestCase {
    func testAttachCreatesEffect() async throws {
        let fx = Effect<Void, Int, Error> { 1 }
        let attached = attach(effect: fx)
        
        var isOriginalFxCalled = false
        fx.watch { _ in isOriginalFxCalled = true }
        
        var isAttachedFxCalled = false
        attached.watch { _ in isAttachedFxCalled = true }
        
        await attached()
        
        XCTAssertFalse(isOriginalFxCalled)
        XCTAssertTrue(isAttachedFxCalled)
    }
    
    func testAttachWithMappedParams() async throws {
        let fx = Effect<Int, Int, Error> { $0 }
        let attached = attach(effect: fx, mapParams: { $0 + 10 })
        
        let got = try await attached(1).get()
        
        XCTAssertEqual(got, 11)
    }
    
    func testAttachEffect() async throws {
        let store = Store(10)
        let inc = Effect<Int, Int, Error> { $0 + 1 }
        
        let fx = attach(
            effect: inc,
            store: store,
            mapParams: { s, p in s + p }
        )
        
        let got = try await fx(1).get()
        
        sleep(1)
        
        XCTAssertEqual(got, 12)
    }
    
    func testAttachEffectFn() async throws {
        let store = Store(10)
        
        let fx: Effect<Int, Int, Error> = attach(
            store: store,
            handler: { s, p in s + p }
        )
        
        let got = try await fx(1).get()
        
        sleep(1)
        
        XCTAssertEqual(got, 11)
    }
}
