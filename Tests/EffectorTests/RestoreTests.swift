@testable import Effector
import XCTest

final class RestoreTests: XCTestCase {
    func testRestore() {
        let event = Event<Int>()
        
        let store = restore(event, 0)
        
        event(1)
        
        XCTAssertEqual(store.getState(), 1)
    }
    
    func testRestoreOptional() {
        let event = Event<Int>()
        
        let store = restore(event)
        
        XCTAssertEqual(store.getState(), nil)
        
        event(1)
        
        XCTAssertEqual(store.getState(), 1)
    }
}
