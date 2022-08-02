public final class Event<Payload>: Unit {
    // MARK: Lifecycle

    public init(name: String = "event", isDerived: Bool = false) {
        self.name = name
        graphite = Node(name: name, kind: .event, priority: .child)
        self.isDerived = isDerived
    }

    // MARK: Public

    public var graphite: Node
    public var name: String

    public var kind: String { "event" }

    public func callAsFunction(_ payload: Payload) {
        run(payload)
    }

    public func run(_ payload: Payload) {
        if isDerived {
            preconditionFailure("call derived event")
        }

        launch(graphite, payload)
    }

    public func watch(_ fn: @escaping (Payload) -> Void) {
        createNode(
            name: "\(name):watch",
            priority: .effect,
            from: [self],
            seq: [.compute("\(name):watch", eraseCompute(fn))]
        )
    }

    public func map<Mapped>(name: String? = nil, _ fn: @escaping (Payload) -> Mapped) -> Event<Mapped> {
        let nodeName = name ?? "\(self.name):map"

        let mapped = Event<Mapped>(name: nodeName, isDerived: true)

        createNode(
            name: nodeName,
            priority: .pure,
            from: [self],
            seq: [.compute(nodeName, eraseCompute(fn))],
            to: [mapped]
        )

        return mapped
    }

    public func prepend<Before>(name: String? = nil, _ fn: @escaping (Before) -> Payload) -> Event<Before> {
        let nodeName = name ?? "\(self.name):prepend"

        let before = Event<Before>(name: nodeName)

        createNode(
            name: nodeName,
            priority: .child,
            from: [before],
            seq: [.compute(nodeName, eraseCompute(fn))],
            to: [self]
        )

        return before
    }

    public func filter(name: String? = nil, _ fn: @escaping (Payload) -> Bool) -> Event<Payload> {
        let nodeName = name ?? "\(self.name):filter"

        let filtered = Event<Payload>(name: nodeName, isDerived: true)

        createNode(
            name: nodeName,
            priority: .pure,
            from: [self],
            // swiftlint:disable:next force_cast
            seq: [.filter(nodeName) { p in fn(p as! Payload) }],
            to: [filtered]
        )

        return filtered
    }

    public func filterMap<Mapped>(name: String? = nil, _ fn: @escaping (Payload) -> Mapped?) -> Event<Mapped> {
        let nodeName = name ?? "\(self.name):filterMap"

        let mapped = Event<Mapped>(name: nodeName, isDerived: true)

        createNode(
            name: nodeName,
            priority: .pure,
            from: [self],
            seq: [
                .compute(nodeName, eraseCompute(fn)),
                // swiftlint:disable:next force_cast
                .filter(nodeName) { x in (x as! Mapped?) != nil },
                // swiftlint:disable:next force_cast
                .compute(nodeName) { x in (x as! Mapped?)! }
            ],
            to: [mapped]
        )

        return mapped
    }

    // MARK: Internal

    var isDerived: Bool
}

public extension Event where Payload == Void {
    func callAsFunction() {
        run(())
    }

    func run() {
        run(())
    }
}
