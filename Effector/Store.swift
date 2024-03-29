import Foundation

public typealias AnyStore = Store<Any>

public final class Store<State>: Unit, ObservableObject {
    // MARK: Lifecycle

    public init(name: String = "store", _ defaultState: State, isDerived: Bool = false) {
        self.name = name
        self.defaultState = defaultState
        currentState = defaultState
        self.isDerived = isDerived

        updates = Event(name: "\(name):updates", isDerived: true)
        reinit = Event(name: "\(name):reinit", isDerived: true)

        graphite = Node(name: name, kind: .store, priority: .child)

        let filter = Node.Step.filter("\(name):filter") { state in
            !areEqual(state, self.currentState)
        }

        let assign = Node.Step.compute("\(name):assign") { state in
            // swiftlint:disable:next force_cast
            let newState = state as! State

            if Thread.isMainThread {
                self.currentState = newState
            } else {
                DispatchQueue.main.sync {
                    self.currentState = newState
                }
            }

            return newState
        }

        graphite.seq.append(contentsOf: [filter, assign])
        graphite.appendNext(updates.graphite)

        if !isDerived {
            reset(reinit)
        }
    }

    // MARK: Public

    public var updates: Event<State>

    public var reinit: Event<Void>

    public var graphite: Node

    public var defaultState: State

    public let name: String

    @Published
    public private(set) var currentState: State

    public private(set) var isDerived: Bool

    public var kind: String { "store" }

    @discardableResult
    public func watch(name: String? = nil, _ fn: @escaping (State) -> Void) -> Subscription {
        let nodeName = name ?? "\(self.name):watch"

        fn(currentState)

        let node = createNode(
            name: nodeName,
            priority: .effect,
            from: [graphite],
            seq: [.compute(nodeName, eraseCompute(fn))]
        )

        return { clear(node) }
    }

    @discardableResult
    public func on<Payload>(
        name: String? = nil,
        _ events: [Event<Payload>],
        _ fn: @escaping (State, Payload) -> State
    ) -> Self {
        // swiftlint:disable:next force_cast
        return onBase(name: name, events) { state, payload in fn(state, payload as! Payload) }
    }

    @discardableResult
    public func on<Payload>(
        name: String? = nil,
        _ event: Event<Payload>,
        _ fn: @escaping (State, Payload) -> State
    ) -> Self {
        // swiftlint:disable:next force_cast
        return onBase(name: name, [event]) { state, payload in fn(state, payload as! Payload) }
    }

    @discardableResult
    public func on<Params, Done, Fail>(
        name: String? = nil,
        _ effect: Effect<Params, Done, Fail>,
        _ fn: @escaping (State, Params) -> State
    ) -> Self {
        // swiftlint:disable:next force_cast
        return onBase(name: name, [effect]) { state, payload in fn(state, payload as! Params) }
    }

    public func getState() -> State {
        currentState
    }

    public func setState(_ state: State) {
        launch(graphite, state)
    }

    public func reset<T>(name: String? = nil, _ events: [Event<T>]) {
        if isDerived {
            preconditionFailure(".reset in derived store")
        }

        let nodeName = name ?? "\(self.name):reset"

        on(name: nodeName, events) { _, _ in self.defaultState }
    }

    public func reset<T>(name: String? = nil, _ event: Event<T>) {
        reset(name: name, [event])
    }

    public func map<Mapped>(name: String? = nil, _ fn: @escaping (State) -> Mapped) -> Store<Mapped> {
        let nodeName = name ?? "\(self.name):map"

        let mapped = Store<Mapped>(name: nodeName, fn(currentState), isDerived: true)

        createNode(
            name: nodeName,
            priority: .pure,
            from: [graphite],
            seq: [.compute(nodeName, eraseCompute(fn))],
            to: [mapped.graphite]
        )

        return mapped
    }

    public func cast<T>() -> Store<T> {
        let store = Store<T>(name: name, defaultState as! T, isDerived: isDerived)

        store.graphite = graphite
        store.reinit = reinit
        store.updates = updates.cast()

        $currentState
            .map { $0 as! T }
            .assign(to: &store.$currentState)

        return store
    }

    public func erase() -> AnyStore {
        cast()
    }

    // MARK: Private

    private func onBase(name: String? = nil, _ units: [Unit], _ fn: @escaping (State, Any) -> State) -> Self {
        if isDerived {
            preconditionFailure("\(self.name).on in derived store")
        }

        let nodeName = name ?? "\(self.name):on"

        createNode(
            name: nodeName,
            priority: .pure,
            from: units.map(\.graphite),
            seq: [.compute(nodeName) { payload in fn(self.currentState, payload) }],
            to: [graphite]
        )

        return self
    }
}

public func areEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    guard lhs is AnyHashable else {
        return false
    }

    guard rhs is AnyHashable else {
        return false
    }

    return (lhs as! AnyHashable) == (rhs as! AnyHashable)
}
