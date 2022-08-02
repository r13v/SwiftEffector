func exec() {
    cycle: while let element = Queue.shared.dequeue() {
        var value = element.value

        for step in element.node.seq {
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

        for node in element.node.next {
            Queue.shared.enqueue(node, value)
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
