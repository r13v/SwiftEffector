public func allSatisfy<Value>(_ stores: [Store<Value>], _ fn: @escaping (Value) -> Bool) -> Store<Bool> {
    let combined = Store<Bool>(
        name: "allSatisfy",
        stores.allSatisfy { fn($0.getState()) },
        isDerived: true
    )

    let stepFn: (Any) -> Bool = { _ in stores.allSatisfy { fn($0.getState()) } }

    createNode(
        name: "allSatisfy",
        kind: .store,
        priority: .combine,
        from: stores,
        seq: [.compute("allSatisfy", eraseCompute(stepFn))],
        to: [combined]
    )

    return combined
}

public func contains<Value>(_ stores: [Store<Value>], _ fn: @escaping (Value) -> Bool) -> Store<Bool> {
    let combined = Store<Bool>(
        name: "contains",
        stores.contains { fn($0.getState()) },
        isDerived: true
    )

    let stepFn: (Any) -> Bool = { _ in stores.contains { fn($0.getState()) } }

    createNode(
        name: "contains",
        kind: .store,
        priority: .combine,
        from: stores,
        seq: [.compute("contains", eraseCompute(stepFn))],
        to: [combined]
    )

    return combined
}
