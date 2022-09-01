public func combine<Combined, A, B>(
    _ a: Store<A>,
    _ b: Store<B>,
    _ fn: @escaping (A, B) -> Combined
) -> Store<Combined> {
    let combined = Store<Combined>(
        name: "combine",
        fn(a.getState(), b.getState()),
        isDerived: true
    )

    let stepFn: (Any) -> Combined = { _ in fn(a.getState(), b.getState()) }

    createNode(
        name: "combine",
        kind: .store,
        priority: .combine,
        from: [a, b],
        seq: [.compute("combine", eraseCompute(stepFn))],
        to: [combined]
    )

    return combined
}

public func combine<Combined, A, B, C>(
    _ a: Store<A>,
    _ b: Store<B>,
    _ c: Store<C>,
    _ fn: @escaping (A, B, C) -> Combined
) -> Store<Combined> {
    let combined = Store<Combined>(
        name: "combine",
        fn(a.getState(), b.getState(), c.getState()),
        isDerived: true
    )

    let stepFn: (Any) -> Combined = { _ in fn(a.getState(), b.getState(), c.getState()) }

    createNode(
        name: "combine",
        kind: .store,
        priority: .combine,
        from: [a, b, c],
        seq: [.compute("combine", eraseCompute(stepFn))],
        to: [combined]
    )

    return combined
}

public func combine<Combined, A, B, C, D>(
    _ a: Store<A>,
    _ b: Store<B>,
    _ c: Store<C>,
    _ d: Store<D>,
    _ fn: @escaping (A, B, C, D) -> Combined
) -> Store<Combined> {
    let combined = Store<Combined>(
        name: "combine",
        fn(a.getState(), b.getState(), c.getState(), d.getState()),
        isDerived: true
    )

    let stepFn: (Any) -> Combined = { _ in fn(a.getState(), b.getState(), c.getState(), d.getState()) }

    createNode(
        name: "combine",
        kind: .store,
        priority: .combine,
        from: [a, b, c, d],
        seq: [.compute("combine", eraseCompute(stepFn))],
        to: [combined]
    )

    return combined
}

public func combine<Combined, A, B, C, D, E>(
    _ a: Store<A>,
    _ b: Store<B>,
    _ c: Store<C>,
    _ d: Store<D>,
    _ e: Store<E>,
    _ fn: @escaping (A, B, C, D, E) -> Combined
) -> Store<Combined> {
    let combined = Store<Combined>(
        name: "combine",
        fn(a.getState(), b.getState(), c.getState(), d.getState(), e.getState()),
        isDerived: true
    )

    let stepFn: (Any) -> Combined = { _ in fn(a.getState(), b.getState(), c.getState(), d.getState(), e.getState()) }

    createNode(
        name: "combine",
        kind: .store,
        priority: .combine,
        from: [a, b, c, d, e],
        seq: [.compute("combine", eraseCompute(stepFn))],
        to: [combined]
    )

    return combined
}

public func combine<Combined, A, B, C, D, E, F>(
    _ a: Store<A>,
    _ b: Store<B>,
    _ c: Store<C>,
    _ d: Store<D>,
    _ e: Store<E>,
    _ f: Store<F>,
    _ fn: @escaping (A, B, C, D, E, F) -> Combined
) -> Store<Combined> {
    let combined = Store<Combined>(
        name: "combine",
        fn(a.getState(), b.getState(), c.getState(), d.getState(), e.getState(), f.getState()),
        isDerived: true
    )

    let stepFn: (Any) -> Combined = { _ in
        fn(
            a.getState(),
            b.getState(),
            c.getState(),
            d.getState(),
            e.getState(),
            f.getState()
        )
    }

    createNode(
        name: "combine",
        kind: .store,
        priority: .combine,
        from: [a, b, c, d, e, f],
        seq: [.compute("combine", eraseCompute(stepFn))],
        to: [combined]
    )

    return combined
}

public protocol InitializableFromDict {
    init(_ dict: [String: Any])
}

public func combine<Combined: InitializableFromDict>(_ stores: [Store<Any>]) -> Store<Combined> {
    let combined = Store<Combined>(
        name: "combine",
        group(stores),
        isDerived: true
    )

    func group(_ stores: [Store<Any>]) -> Combined {
        var dict = [String: Any]()

        for store in stores {
            dict[store.name] = store.getState()
        }

        return Combined(dict)
    }

    let stepFn: (Any) -> Combined = { _ in group(stores) }

    createNode(
        name: "combine",
        kind: .store,
        priority: .combine,
        from: stores,
        seq: [.compute("combine", eraseCompute(stepFn))],
        to: [combined]
    )

    return combined
}
