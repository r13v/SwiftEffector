@testable import Effector
import XCTest

final class AllSettledTests: XCTestCase {
    func testEvent() async throws {
        let event = Event<Int>()
        
        let store = Store(0)
        
        sample(
            trigger: event,
            map: { payload in payload + 10 },
            target: store
        )
        
        await allSettled(event: event, payload: 10)
        
        XCTAssertEqual(store.getState(), 20)
    }
    
    func testEventWithVoidPayload() async throws {
        let event = Event<Void>()
        
        let store = Store(0)
        
        sample(
            trigger: event,
            map: { _ in 10 },
            target: store
        )
        
        await allSettled(event: event)
        
        XCTAssertEqual(store.getState(), 10)
    }
    
    func testEventWithDependentEffects() async throws {
        let event = Event<Int>()
        
        let store1 = Store(0)
        let store2 = Store(0)

        let fx = Effect<Int, Int, Error>() { params in
            try await Task.sleep(nanoseconds: 1_000_000)
            
            return params + 100
        }
        
        store1.on(event) { $1 }
        store2.on(fx.doneData) { $1 }
        
        sample(
            trigger: store1.updates,
            target: fx
        )
        
        await allSettled(event: event, payload: 10)
        
        XCTAssertEqual(store1.getState(), 10)
        XCTAssertEqual(store2.getState(), 110)
    }
}
