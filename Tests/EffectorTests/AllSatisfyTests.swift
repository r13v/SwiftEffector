@testable import Effector
import XCTest

final class AllSatisfyTests: XCTestCase {
    func testAllSatisfy() async throws {
        let a = Store(2)
        let b = Store(3)
        
        let c = allSatisfy([a, b]) { $0 > 0 }
        
        XCTAssert(c.getState())
    }
    
    func testAllSatisfyChanged() async throws {
        let a = Store(-1)
        let b = Store(3)
        
        let c = allSatisfy([a, b]) { $0 > 0 }
        
        XCTAssert(!c.getState())
        
        a.setState(1)
        
        XCTAssert(c.getState())
    }
}
