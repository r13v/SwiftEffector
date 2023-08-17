public func attach<Params, MappedParams, Done, MappedDone, Fail>(
    name: String? = nil,
    effect: Effect<MappedParams, Done, Fail>,
    mapParams: @escaping (Params) -> MappedParams,
    mapResult: @escaping (Done) -> MappedDone
) -> Effect<Params, MappedDone, Fail> {
    let handler = effect.getCurrent()

    let attached = Effect<Params, MappedDone, Fail>(name: name ?? "attach", isDerived: true) { params in
        let result = try await handler(mapParams(params))

        return mapResult(result)
    }

    return attached
}

public func attach<Params, MappedParams, Done, Fail>(
    name: String? = nil,
    effect: Effect<MappedParams, Done, Fail>,
    mapParams: @escaping (Params) -> MappedParams
) -> Effect<Params, Done, Fail> {
    return attach(name: name, effect: effect, mapParams: mapParams, mapResult: { $0 })
}

public func attach<Params, Done, MappedDone, Fail>(
    name: String? = nil,
    mapResult: @escaping (Done) -> MappedDone,
    effect: Effect<Params, Done, Fail>
) -> Effect<Params, MappedDone, Fail> {
    return attach(name: name, effect: effect, mapParams: { $0 }, mapResult: mapResult)
}

public func attach<Params, Done, Fail>(
    name: String? = nil,
    effect: Effect<Params, Done, Fail>
) -> Effect<Params, Done, Fail> {
    return attach(name: name, effect: effect, mapParams: { $0 }, mapResult: { $0 })
}

// MARK: - Attach with `store`

public func attach<State, Params, MappedParams, Done, MappedDone, Fail>(
    name: String? = nil,
    effect: Effect<MappedParams, Done, Fail>,
    store: Store<State>,
    mapParams: @escaping (State, Params) -> MappedParams,
    mapResult: @escaping (Done) -> MappedDone
) -> Effect<Params, MappedDone, Fail> {
    let fn = effect.getCurrent()

    let fx = Effect<Params, MappedDone, Fail>(name: name ?? "attach", isDerived: true) { params in
        let mapped = mapParams(store.getState(), params)

        let result = try await fn(mapped)

        return mapResult(result)
    }

    return fx
}

public func attach<State, Params, MappedParams, Done, Fail>(
    name: String? = nil,
    effect: Effect<MappedParams, Done, Fail>,
    store: Store<State>,
    mapParams: @escaping (State, Params) -> MappedParams
) -> Effect<Params, Done, Fail> {
    return attach(name: name, effect: effect, store: store, mapParams: mapParams, mapResult: { $0 })
}

public func attach<State, Done, Fail>(
    name: String? = nil,
    effect: Effect<State, Done, Fail>,
    store: Store<State>
) -> Effect<State, Done, Fail> {
    return attach(name: name, effect: effect, store: store, mapParams: { state, _ in state }, mapResult: { $0 })
}

// MARK: - With handler param

public func attach<State, Params, Done, Fail>(
    name: String? = nil,
    store: Store<State>,
    handler: @escaping (_ state: State, _ params: Params) async throws -> Done
) -> Effect<Params, Done, Fail> {
    let effect = Effect<Params, Done, Fail>(name: name ?? "attach", isDerived: true) { params in
        try await handler(store.getState(), params)
    }

    return effect
}
