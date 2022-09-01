import Foundation

public final class Store<State>: Unit, ObservableObject {
    // MARK: Lifecycle

    public init(name: String = "store", _ defaultState: State, isDerived: Bool = false) {
        self.name = name
        self.defaultState = defaultState
        currentState = defaultState
        self.isDerived = isDerived

        updates = Event(name: "\(name):updates", isDerived: true)

        graphite = Node(name: "store", kind: .store, priority: .child)
        let step = Node.Step.compute("state:assign") { state in
            // swiftlint:disable:next force_cast
            let newState = state as! State

            if !areEqual(self.currentState, newState) {
                if Thread.isMainThread {
                    self.currentState = newState
                } else {
                    DispatchQueue.main.sync {
                        self.currentState = newState
                    }
                }
            }

            return newState
        }
        graphite.seq.append(step)
        graphite.appendNext(updates.graphite)
    }

    // MARK: Public

    public var updates: Event<State>

    public var graphite: Node

    public var defaultState: State

    public let name: String

    @Published public private(set) var currentState: State

    public var kind: String { "store" }

    public func watch(name: String? = nil, _ fn: @escaping (State) -> Void) {
        let nodeName = name ?? "\(self.name):watch"

        fn(currentState)

        createNode(
            name: nodeName,
            priority: .effect,
            from: [self],
            seq: [.compute(nodeName, eraseCompute(fn))]
        )
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
        let nodeName = name ?? "\(self.name):reset"

        let mapped = Store<Mapped>(name: nodeName, fn(currentState), isDerived: true)

        createNode(
            name: nodeName,
            priority: .pure,
            from: [self],
            seq: [.compute(nodeName, eraseCompute(fn))],
            to: [mapped]
        )

        return mapped
    }

    // MARK: Internal

    var isDerived: Bool

    // MARK: Private

    private func onBase(name: String? = nil, _ units: [Unit], _ fn: @escaping (State, Any) -> State) -> Self {
        if isDerived {
            preconditionFailure("\(self.name).on in derived store")
        }

        let nodeName = name ?? "\(self.name):on"

        createNode(
            name: nodeName,
            priority: .pure,
            from: units,
            seq: [.compute(nodeName) { payload in fn(self.currentState, payload) }],
            to: [self]
        )

        return self
    }
}
