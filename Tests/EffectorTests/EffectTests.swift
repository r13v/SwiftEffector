@testable import Effector
import XCTest

final class EffectTests: XCTestCase {
    func testEffectReturns() async throws {
        let inc = Effect<Int, Int, Error> { $0 + 1 }
        
        let got = try await inc(1)
        
        XCTAssertEqual(got, 2)
    }
    
    func testEffectThrows() async throws {
        enum EffectError: Error {
            case unknown
        }
        
        let effect = Effect<Void, Void, EffectError> { throw EffectError.unknown }
        
        do {
            try await effect()
            XCTAssert(false)
            
        } catch {
            // swiftlint:disable:next force_cast
            XCTAssertEqual(error as! EffectError, EffectError.unknown)
        }
    }
    
    func testEffectWatch() async throws {
        var log = [Int]()
        let inc = Effect<Int, Int, Error> { $0 + 1 }
        inc.watch { log.append($0) }
        
        try await inc(10)
        
        sleep(1)
        
        XCTAssertEqual(log, [10])
    }
    
    func testEffectPrepend() async throws {
        let store = Store(0)
        let inc = Effect<Int, Int, Error> { $0 + 1 }
        let before = inc.prepend { $0 + 10 }
        
        store.on(inc.doneData) { _, n in n }
        
        before(10)
        
        sleep(1)
        
        XCTAssertEqual(store.getState(), 21)
    }
    
    func testEffectGetHandler() async throws {
        let inc = Effect<Int, Int, Error> { $0 + 1 }
        let original = inc.getCurrent()
        let got = try await original(1)
        
        XCTAssertEqual(got, 2)
    }
    
    func testEffectReplaceHandler() async throws {
        let inc = Effect<Int, Int, Error> { $0 + 1 }
        inc.use { $0 + 2 }
        
        let got = try await inc(1)
        
        XCTAssertEqual(got, 3)
    }
    
    func testEffectFinally() async throws {
        let store = Store<Effect<Int, Int, Error>.Finally?>(nil)
        let inc = Effect<Int, Int, Error> { $0 + 1 }
        store.on(inc.finally) { _, n in n }
        
        try await inc(1)
        
        sleep(1)
        
        if case let .done(params, done) = store.getState() {
            XCTAssertEqual(params, 1)
            XCTAssertEqual(done, 2)
        } else {
            XCTAssert(false)
        }
    }
    
    func testEffectDone() async throws {
        let store = Store<(params: Int, done: Int)?>(nil)
        let inc = Effect<Int, Int, Error> { $0 + 1 }
        store.on(inc.done) { _, n in n }
        
        try await inc(1)
        
        sleep(1)
        
        let got = store.getState()
        
        XCTAssertEqual(got?.params, 1)
        XCTAssertEqual(got?.done, 2)
    }
    
    func testEffectFail() async throws {
        struct Err: Error {}
        
        let store = Store<(params: Int, fail: Err)?>(nil)
        let inc = Effect<Int, Int, Err> { _ in throw Err() }
        
        store.on(inc.fail) { _, n in n }
        
        _ = try? await inc(1)
        
        sleep(1)
        
        let got = store.getState()
        
        XCTAssertEqual(got?.params, 1)
        XCTAssert(got?.fail is Err)
    }
    
    func testEffectInPending() async throws {
        var log = [Bool]()
        let inc = Effect<Int, Int, Error> { $0 + 1 }
        
        inc.pending.watch { log.append($0) }
        
        try await inc(1)
        
        XCTAssertEqual(log, [false, true, false])
    }
}
