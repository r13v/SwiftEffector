public final class Node {
    // MARK: Lifecycle

    init(
        name: String,
        kind: Kind,
        priority: PriorityTag,
        next: [Node] = [],
        seq: [Step] = []
    ) {
        id = Node.nextID()
        self.name = name
        self.kind = kind
        self.priority = priority
        self.next = next
        self.seq = seq
    }

    // MARK: Internal

    enum Kind: String {
        case regular, event, store, effect
    }

    enum Step {
        case compute(String, (Any) -> Any)
        case filter(String, (Any) -> Bool)
    }

    enum PriorityTag: Int {
        case child = 1 // forward
        case pure = 2 // on, map
        case combine = 3 // combine
        case sample = 4 // sample
        case effect = 5 // watch, effect handler
    }

    let id: String
    let name: String
    let kind: Kind
    let priority: PriorityTag

    private(set) var next: [Node]
    var seq: [Step]

    func appendNext(_ node: Node) {
        next.append(node)
    }

    func prependNext(_ node: Node) {
        next.insert(node, at: 0)
    }

    func clear() {
        next = []
        seq = []
    }

    // MARK: Private

    private static let nextID = uniqId("n-")
}

extension Node: CustomStringConvertible {
    public var description: String {
        "[\(id):\(kind)] \(name)"
    }
}

@discardableResult
func createNode(
    name: String,
    kind: Node.Kind = .regular,
    priority: Node.PriorityTag,
    from: [Unit] = [],
    seq: [Node.Step] = [],
    to: [Unit] = []
) -> Node {
    let next = to.map(\.graphite)

    let node = Node(
        name: name,
        kind: kind,
        priority: priority,
        next: next,
        seq: seq
    )

    from.forEach { unit in
        unit.graphite.appendNext(node)
    }

    return node
}
