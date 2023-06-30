// swiftlint:disable file_length

@testable import Effector
import XCTest

// swiftlint:disable:next type_body_length
final class EffectorTests: XCTestCase {
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

    func testEventWatch() async throws {
        let event = Event<Int>()

        var log: [Int] = []

        event.watch { int in
            log.append(int)
        }

        event(10)

        XCTAssertEqual([10], log)
    }

    func testEventMap() async throws {
        let event = Event<Int>()
        let mapped = event.map { $0 + 1 }
        var log: [Int] = []
        mapped.watch { log.append($0) }

        event(1)

        XCTAssertEqual([2], log)
    }

    func testEventPrepend() async throws {
        let event = Event<Int>()
        var log: [Int] = []
        event.watch { log.append($0) }
        let before: Event<Int> = event.prepend { $0 + 1 }

        before(1)

        XCTAssertEqual([2], log)
    }

    func testEventFilter() async throws {
        let event = Event<Int>()
        let filtered = event.filter { $0 > 0 }
        var log: [Int] = []
        filtered.watch { log.append($0) }

        event(1)
        event(-1)
        event(2)

        XCTAssertEqual([1, 2], log)
    }

    func testEventFilterMap() async throws {
        let event = Event<Int>()
        let filtered: Event<Int> = event.filterMap { n in
            if n < 0 {
                return nil
            }

            return n + 10
        }
        var log: [Int] = []

        filtered.watch { log.append($0) }

        event(1)
        event(-1)
        event(10)

        XCTAssertEqual([11, 20], log)
    }

    func testStoreSetState() async throws {
        let store = Store<Int>(0)

        store.setState(1)

        XCTAssertEqual(store.getState(), 1)
    }

    func testStoreNot() async throws {
        let store = Store(false)
        let inverted = store.not()

        XCTAssertEqual(inverted.getState(), true)

        store.setState(true)

        XCTAssertEqual(inverted.getState(), false)
    }

    func testStoreOn() async throws {
        let inc = Event<Void>()
        let reset = Event<Void>()

        let store = Store<Int>(0)
        var log: [Int] = []

        store.on(inc) { state, _ in
            state + 1
        }
        .reset(reset)

        store.watch { log.append($0) }

        inc()
        inc()
        inc()

        XCTAssertEqual(log, [0, 1, 2, 3])
        XCTAssertEqual(store.getState(), 3)

        reset()

        XCTAssertEqual(0, store.getState())
    }

    func testStoreMap() async throws {
        let store = Store(1)
        let inc = Event<Void>()

        let mapped = store.map { $0 + 1 }

        XCTAssertEqual(store.getState(), 1)
        XCTAssertEqual(mapped.getState(), 2)

        store.on(inc) { n, _ in n + 1 }

        inc()

        XCTAssertEqual(store.getState(), 2)
        XCTAssertEqual(mapped.getState(), 3)
    }

    func testStoreDefaultState() async throws {
        let store = Store(1)
        let inc = Event<Void>()

        store.on(inc) { state, _ in
            state + 1
        }

        inc()

        XCTAssertEqual(store.getState(), 2)
        XCTAssertEqual(store.defaultState, 1)
    }

    func testStoreUpdates() async throws {
        var log: [Int] = []
        let store = Store(1)
        let inc = Event<Void>()

        store.on(inc) { state, _ in
            state + 1
        }

        store.updates.watch { log.append($0) }

        inc()

        XCTAssertEqual(log, [2])
    }

    func testForward() async throws {
        let event = Event<Int>()
        let store = Store<Int>(0)
        var log: [Int] = []
        store.watch { log.append($0) }
        forward(from: [event], to: [store])

        event(1)
        event(2)

        XCTAssertEqual(log, [0, 1, 2])
        XCTAssertEqual(store.getState(), 2)
    }

    func testMerge() async throws {
        let event1 = Event<Int>()
        let event2 = Event<Int>()
        let merged = merge(event1, event2)
        let store = Store<Int>(0)
        var log: [Int] = []

        merged.watch { log.append($0) }
        store.on(merged) { n, x in n + x }

        event1(1)
        event2(2)

        XCTAssertEqual(log, [1, 2])
        XCTAssertEqual(store.getState(), 3)
    }

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

    func testQueuePriority() async throws {
        /*
         case child = 1 // forward
         case pure = 2 // on, map
         case combine = 3 // combine
         case sample = 4 // sample
         case effect = 5 // watch, effect handler
         */

        let queue = Queue()

        let event1 = Event<Int>(name: "event1")
        queue.enqueue(event1.graphite, 1)

        let store = Store(name: "store", 1)
        queue.enqueue(store.graphite, 0)

        let effect = Effect<Int, Int, Error>(name: "effect", { n in n + 1 })
        queue.enqueue(effect.graphite, 0)

        let forward = Node(name: "forward", kind: .regular, priority: .child)
        queue.enqueue(forward, 0)

        // swiftlint:disable:next identifier_name
        let on = Node(name: "on", kind: .regular, priority: .pure)
        queue.enqueue(on, 0)

        let map = Node(name: "map", kind: .regular, priority: .pure)
        queue.enqueue(map, 0)

        let combine = Node(name: "combine", kind: .regular, priority: .combine)
        queue.enqueue(combine, 0)

        let sample = Node(name: "sample", kind: .regular, priority: .sample)
        queue.enqueue(sample, 0)

        let watch = Node(name: "watch", kind: .regular, priority: .effect)
        queue.enqueue(watch, 0)

        let event2 = Event<Int>(name: "event2")
        queue.enqueue(event2.graphite, 1)

        var list = [String]()

        while let element = queue.dequeue() {
            list.append(element.node.name)
        }

        XCTAssertEqual(
            list,
            [
                "event1",
                "store",
                "forward",
                "event2",
                "on",
                "map",
                "combine",
                "sample",
                "effect",
                "watch"
            ]
        )
    }

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
