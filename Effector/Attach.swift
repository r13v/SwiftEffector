public func attach<State, Params, Done, Fail>(
    name: String? = nil,
    store: Store<State>,
    effect fn: @escaping (State, Params) async throws -> Done
) -> Effect<Params, Done, Fail> {
    let fx = Effect<Params, Done, Fail>(name: name ?? "attach", isDerived: true) { params in
        try await fn(store.getState(), params)
    }

    return fx
}

public func attach<State, Mapped, Params, Done, Fail>(
    name: String? = nil,
    store: Store<State>,
    map: @escaping (State, Params) -> Mapped,
    effect: Effect<Mapped, Done, Fail>
) -> Effect<Params, Done, Fail> {
    let effectFn = effect.getCurrent()
    let fx = Effect<Params, Done, Fail>(name: name ?? "attach", isDerived: true) { params in
        let mapped = map(store.getState(), params)
        return try await effectFn(mapped)
    }

    return fx
}
