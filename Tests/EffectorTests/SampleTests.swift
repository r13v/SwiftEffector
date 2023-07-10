@testable import Effector
import XCTest

final class SampleTests: XCTestCase {
    func testSampleBasic() async throws {
        var log = [Int]()
        let trigger = Event<Int>()
        
        let sample = sample(trigger: trigger)
        
        sample.watch { log.append($0) }
        
        trigger(1)
        
        XCTAssertEqual(log, [1])
    }
    
    func testSampleReturnedEvent() async throws {
        var log = [Int]()
        let trigger = Event<Int>()
        let source = Store(1)
        
        let sample = sample(
            trigger: trigger,
            source: source,
            filter: { s, p in s + p > 0 },
            map: { s, p in s + p }
        )
        
        sample.watch { log.append($0) }
        
        trigger(-10)
        trigger(1)
        
        XCTAssertEqual(log, [2])
    }
    
    func testSampleEventToEvent() async throws {
        var log = [Int]()
        let trigger = Event<Int>()
        let source = Store(1)
        let target = Event<Int>()
        
        sample(
            trigger: trigger,
            source: source,
            filter: { s, p in s + p > 0 },
            map: { s, p in s + p },
            target: target
        )
        
        target.watch { log.append($0) }
        
        trigger(-10)
        trigger(1)
        
        XCTAssertEqual(log, [2])
    }
    
    func testSampleEventToStore() async throws {
        let trigger = Event<Int>()
        let target = Store<Int>(0)
        
        sample(
            trigger: trigger,
            source: Store(1),
            filter: { s, p in s + p > 0 },
            map: { s, p in s + p },
            target: target
        )
        
        trigger(-10)
        trigger(1)
        
        XCTAssertEqual(target.getState(), 2)
    }
    
    func testSampleEventToEffect() async throws {
        var log = [Int]()
        let trigger = Event<Int>()
        let target = Effect<Int, Int, Error> { n in
            try await Task.sleep(nanoseconds: 1000)
            return n + 10
        }
        
        target.doneData.watch { log.append($0) }
        
        sample(
            trigger: trigger,
            target: target
        )
        
        trigger(-10)
        
        sleep(1)
        
        XCTAssertEqual(log, [0])
    }
    
    func testSampleEventToEffectMapped() async throws {
        var log = [String]()
        let trigger = Event<Int>()
        let target = Effect<String, String, Error> { $0 }
        
        target.doneData.watch { log.append($0) }
        
        sample(
            trigger: trigger,
            map: { "n = \($0)" },
            target: target
        )
        
        trigger(10)
        
        XCTAssertEqual(log, ["n = 10"])
    }
}
