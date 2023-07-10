@testable import Effector
import XCTest

final class QueueTests: XCTestCase {
    func testQueuePriority() async throws {
        /*
         case child = 1 // event, forward
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
}
