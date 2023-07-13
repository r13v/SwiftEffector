@testable import Effector
import XCTest

final class DomainTests: XCTestCase {
    func testEventWatch() async throws {
        let domain = Domain("app")
        
        var log = [Int]()
        
        domain.onCreateEvent = { event in
            event.watch { value in
                log.append(value as! Int)
            }
        }
        
        let event = Event<Int>(domain: domain)
        
        event(1)
        event(2)
        
        XCTAssertEqual(log, [1, 2])
    }
    
    func testStoreReset() async throws {
        let domain = Domain("app")
        
        let reset = Event<Void>()
        
        domain.onCreateStore = { store in
            store.reset(reset)
        }
        
        let storeA = Store<Int>(0, domain: domain)
        let storeB = Store<Int>(0, domain: domain)
        
        storeA.setState(1)
        storeB.setState(1)
        
        XCTAssertEqual(storeA.getState(), 1)
        XCTAssertEqual(storeB.getState(), 1)
        
        reset()
        
        XCTAssertEqual(storeA.getState(), 0)
        XCTAssertEqual(storeB.getState(), 0)
    }
    
    func testSubdomain() async throws {
        let app = Domain("app")
        let domain = Domain("sub", parent: app)
        
        var log = [Int]()
        
        app.onCreateEvent = { event in
            event.watch { value in
                log.append(value as! Int)
            }
        }
        
        let event = Event<Int>(domain: domain)
        
        event(1)
        event(2)
        
        XCTAssertEqual(log, [1, 2])
    }
}
