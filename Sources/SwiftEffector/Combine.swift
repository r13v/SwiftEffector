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
