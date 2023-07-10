enum Tracing {
    @TaskLocal
    static var id: String = next()

    static let next = uniqId("trace-")
}

public final class Effect<Params, Done, Fail: Error>: Unit {
    // MARK: Lifecycle

    // swiftlint:disable:next function_body_length
    public init(name: String = "effect", isDerived: Bool = false, _ handler: @escaping Handler) {
        self.name = name
        self.isDerived = isDerived
        graphite = Node(name: name, kind: .effect, priority: .effect)

        self.handler = handler

        inFlight = Store(name: "\(name):inFlight", 0)
        pending = inFlight.map(name: "\(name):pending") { $0 > 0 }

        finally = Event<Finally>(name: "\(name):finally", isDerived: true)

        done = finally
            .filterMap(name: "\(name):done") { result in
                guard case let .done(params, done) = result else {
                    return nil
                }

                return (params: params, done: done)
            }

        fail = finally
            .filterMap(name: "\(name):fail") { result in
                guard case let .fail(params, fail) = result else {
                    return nil
                }

                return (params: params, fail: fail)
            }

        doneData = done.map(name: "\(name):doneData") { $0.1 }
        failData = fail.map(name: "\(name):failData") { $0.1 }

        inFlight
            .on(self) { n, _ in n + 1 }
            .on(finally) { n, _ in n - 1 }

        let enqueueRunner: (Any) -> Params = { data in
            let effectParams: EffectParams

            if data is EffectParams {
                // swiftlint:disable:next force_cast
                effectParams = data as! EffectParams
            } else {
                // swiftlint:disable:next force_cast
                effectParams = EffectParams(params: data as! Params, resolve: { _ in }, reject: { _ in })
            }

            let traceID = "\(self.graphite.id):\(Tracing.id)"

            let runner = Node.Step.compute("\(name):runner") { _ in
                Task {
                    do {
                        let done = try await self.handler(effectParams.params)

                        launch(self.finally.graphite, Finally.done(effectParams.params, done))

                        effectParams.resolve(done)
                    } catch {
                        // swiftlint:disable:next force_cast
                        launch(self.finally.graphite, Finally.fail(effectParams.params, error as! Fail))

                        // swiftlint:disable:next force_cast
                        effectParams.reject(error as! Fail)
                    }
                }

                return effectParams.params
            }

            let runnerNode = createNode(
                name: "\(name):runner:\(traceID)",
                kind: .regular,
                priority: .effect,
                seq: [runner]
            )

            let enqueuerNode = Node(
                name: "\(name):enqueuer:\(traceID)",
                kind: .regular,
                priority: .effect,
                next: [runnerNode]
            )

            defer {
                launch(enqueuerNode, ())
            }

            return effectParams.params
        }

        graphite.seq.append(contentsOf: [
            .compute("\(name):enqueueRunner", eraseCompute(enqueueRunner))
        ])
    }

    // MARK: Public

    public enum Finally {
        case done(Params, Done)
        case fail(Params, Fail)
    }

    public typealias Handler = (Params) async throws -> Done

    public var finally: Event<Finally>
    public var done: Event<(Params, Done)>
    public var fail: Event<(Params, Fail)>
    public var doneData: Event<Done>
    public var failData: Event<Fail>
    public var inFlight: Store<Int>
    public var pending: Store<Bool>

    public var graphite: Node

    public var name: String

    public private(set) var isDerived: Bool

    public var kind: String { "effect" }

    @discardableResult
    public func callAsFunction(_ params: Params) async throws -> Done {
        return try await run(params)
    }

    @discardableResult
    public func run(_ params: Params) async throws -> Done {
        return try await Tracing.$id.withValue(Tracing.next()) {
            try await withCheckedThrowingContinuation { continuation in

                let effectParams = EffectParams(
                    params: params,
                    resolve: continuation.resume(returning:),
                    reject: continuation.resume(throwing:)
                )

                launch(self.graphite, effectParams)
            }
        }
    }

    public func use(_ fn: @escaping Handler) {
        handler = fn
    }

    public func getCurrent() -> Handler {
        handler
    }

    @discardableResult
    public func watch(name: String? = nil, _ fn: @escaping (Params) -> Void) -> Subscription {
        let nodeName = name ?? "\(self.name):watch"

        let node = createNode(
            name: nodeName,
            priority: .effect,
            from: [graphite],
            seq: [.compute(nodeName, eraseCompute(fn))]
        )

        return { clear(node) }
    }

    public func prepend<Before>(name: String? = nil, _ fn: @escaping (Before) -> Params) -> Event<Before> {
        let nodeName = name ?? "\(self.name):prepend"

        let before = Event<Before>(name: nodeName)

        createNode(
            name: nodeName,
            priority: .child,
            from: [before.graphite],
            seq: [.compute(nodeName, eraseCompute(fn))],
            to: [graphite]
        )

        return before
    }

    // MARK: Internal

    struct EffectParams {
        var params: Params
        var resolve: (Done) -> Void
        var reject: (Fail) -> Void
    }

    var handler: Handler
}

public extension Effect where Params == Void {
    @discardableResult
    func callAsFunction() async throws -> Done {
        try await run(())
    }

    @discardableResult
    func run() async throws -> Done {
        try await run(())
    }
}
