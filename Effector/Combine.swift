import Foundation

public func combine<Combined, A, B>(
    _ a: Store<A>,
    _ b: Store<B>,
    _ fn: @escaping (A, B) -> Combined
) -> Store<Combined> {
    let combined = Store<Combined>(
        name: "combine(\(a.name), \(b.name))",
        fn(a.getState(), b.getState()),
        isDerived: true
    )

    let stepFn: (Any) -> Combined = { _ in fn(a.getState(), b.getState()) }

    createNode(
        name: "combine",
        kind: .store,
        priority: .combine,
        from: [a.graphite, b.graphite],
        seq: [.compute("combine", eraseCompute(stepFn))],
        to: [combined.graphite]
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
        name: "combine(\(a.name), \(b.name), \(c.name))",
        fn(a.getState(), b.getState(), c.getState()),
        isDerived: true
    )

    let stepFn: (Any) -> Combined = { _ in fn(a.getState(), b.getState(), c.getState()) }

    createNode(
        name: "combine",
        kind: .store,
        priority: .combine,
        from: [a.graphite, b.graphite, c.graphite],
        seq: [.compute("combine", eraseCompute(stepFn))],
        to: [combined.graphite]
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
        name: "combine(\(a.name), \(b.name), \(c.name), \(d.name))",
        fn(a.getState(), b.getState(), c.getState(), d.getState()),
        isDerived: true
    )

    let stepFn: (Any) -> Combined = { _ in fn(a.getState(), b.getState(), c.getState(), d.getState()) }

    createNode(
        name: "combine",
        kind: .store,
        priority: .combine,
        from: [a.graphite, b.graphite, c.graphite, d.graphite],
        seq: [.compute("combine", eraseCompute(stepFn))],
        to: [combined.graphite]
    )

    return combined
}

// swiftlint:disable:next function_parameter_count
public func combine<Combined, A, B, C, D, E>(
    _ a: Store<A>,
    _ b: Store<B>,
    _ c: Store<C>,
    _ d: Store<D>,
    _ e: Store<E>,
    _ fn: @escaping (A, B, C, D, E) -> Combined
) -> Store<Combined> {
    let combined = Store<Combined>(
        name: "combine(\(a.name), \(b.name), \(c.name), \(d.name), \(e.name))",
        fn(a.getState(), b.getState(), c.getState(), d.getState(), e.getState()),
        isDerived: true
    )

    let stepFn: (Any) -> Combined = { _ in fn(a.getState(), b.getState(), c.getState(), d.getState(), e.getState()) }

    createNode(
        name: "combine",
        kind: .store,
        priority: .combine,
        from: [a.graphite, b.graphite, c.graphite, d.graphite, e.graphite],
        seq: [.compute("combine", eraseCompute(stepFn))],
        to: [combined.graphite]
    )

    return combined
}

// swiftlint:disable:next function_parameter_count
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
        name: "combine(\(a.name), \(b.name), \(c.name), \(d.name), \(e.name), \(f.name))",
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
        from: [a.graphite, b.graphite, c.graphite, d.graphite, e.graphite, f.graphite],
        seq: [.compute("combine", eraseCompute(stepFn))],
        to: [combined.graphite]
    )

    return combined
}

public func combine<Combined: Decodable>(_ stores: [AnyStore]) -> Store<Combined> {
    let jsonDecoder = JSONDecoder()

    let names = stores.map { $0.name }.joined(separator: ", ")

    let combined = Store<Combined>(
        name: "combine(\(names))",
        group(decoder: jsonDecoder, stores: stores),
        isDerived: true
    )

    func group(decoder: JSONDecoder, stores: [AnyStore]) -> Combined {
        var dict = [String: Any]()

        for store in stores {
            dict[store.name] = store.getState()
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []),
              let result = try? jsonDecoder.decode(Combined.self, from: jsonData)
        else {
            fatalError("Can't combine to \(type(of: Combined.self))")
        }

        return result
    }

    let stepFn: (Any) -> Combined = { _ in group(decoder: jsonDecoder, stores: stores) }

    createNode(
        name: "combine",
        kind: .store,
        priority: .combine,
        from: stores.map(\.graphite),
        seq: [.compute("combine", eraseCompute(stepFn))],
        to: [combined].map(\.graphite)
    )

    return combined
}
