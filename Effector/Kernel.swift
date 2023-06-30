let DEBUG = false

func debugPrint(_ message: String) {
    if DEBUG {
        print(message)
    }
}

func exec() {
    debugPrint("--- exec ---")

    cycle: while let element = Queue.shared.dequeue() {
        let node = element.node
        var value = element.value

        debugPrint("cycle \(node), \(value)")

        for step in node.seq {
            switch step {
            case let .compute(_, fn):
                value = fn(value)

            case let .filter(_, fn):
                let ok = fn(value)

                if !ok {
                    continue cycle
                }
            }
        }

        for nextNode in element.node.next {
            debugPrint("enqueue \(node), \(value)")

            Queue.shared.enqueue(nextNode, value)
        }
    }
}

func launch<Payload>(_ node: Node, _ payload: Payload) {
    Queue.shared.enqueue(node, payload)

    exec()
}

func eraseCompute<Payload, Return>(_ fn: @escaping (Payload) -> Return) -> (Any) -> Any {
    // swiftlint:disable:next force_cast
    { arg in fn(arg as! Payload) }
}
