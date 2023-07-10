@testable import Effector
import XCTest

final class ContainsTests: XCTestCase {
    func testContains() async throws {
        let a = Store(-1)
        let b = Store(3)
        
        let c = contains([a, b]) { $0 > 0 }
        
        XCTAssert(c.getState())
    }
    
    func testContainsChanged() async throws {
        let a = Store(-1)
        let b = Store(-2)
        
        let c = contains([a, b]) { $0 > 0 }
        
        XCTAssert(!c.getState())
        
        a.setState(1)
        
        XCTAssert(c.getState())
    }
}
