func linkBase<Payload, State, Mapped>(
    name: String? = nil,
    trigger: Event<Payload>,
    source: Store<State>,
    filter: ((State, Payload) -> Bool)? = nil,
    map: ((State, Payload) -> Mapped)? = nil,
    target: Unit? = nil
) -> Event<Mapped> {
    let sampleName = name ?? "sample:(\(source.name), \(trigger.name)) -> \(target?.name ?? "*")"
    let targetEvent = Event<Mapped>(name: sampleName, isDerived: true)

    var seq = [Node.Step]()

    if let filter = filter {
        seq.append(
            // swiftlint:disable:next force_cast
            .filter(sampleName) { payload in filter(source.getState(), payload as! Payload) }
        )
    }

    // swiftlint:disable:next force_cast
    let mapFn = map ?? { s, _ in s as! Mapped }
    // swiftlint:disable:next force_cast
    seq.append(.compute(sampleName) { payload in mapFn(source.getState(), payload as! Payload) })

    var nextNodes: [Unit] = [targetEvent]

    if let target = target {
        nextNodes.append(target)
    }

    createNode(
        name: sampleName,
        kind: .event,
        priority: .link,
        from: [trigger],
        seq: seq,
        to: nextNodes
    )

    return targetEvent
}

func linkBase<Payload, Mapped>(
    name: String? = nil,
    trigger: Event<Payload>,
    filter: ((Payload) -> Bool)? = nil,
    map: ((Payload) -> Mapped)? = nil,
    target: Unit? = nil
) -> Event<Mapped> {
    let sampleName = name ?? "sample:(\(trigger.name)) -> \(target?.name ?? "*")"
    let targetEvent = Event<Mapped>(name: sampleName, isDerived: true)

    var seq = [Node.Step]()

    if let filter = filter {
        seq.append(
            // swiftlint:disable:next force_cast
            .filter(sampleName) { payload in filter(payload as! Payload) }
        )
    }

    if let map = map {
        seq.append(
            // swiftlint:disable:next force_cast
            .compute(sampleName) { payload in map(payload as! Payload) }
        )
    }

    var nextNodes: [Unit] = [targetEvent]

    if let target = target {
        nextNodes.append(target)
    }

    createNode(
        name: sampleName,
        kind: .event,
        priority: .link,
        from: [trigger],
        seq: seq,
        to: nextNodes
    )

    return targetEvent
}

// Link with source

@discardableResult
func link<Payload, State, Mapped>(
    name: String? = nil,
    trigger: Event<Payload>,
    source: Store<State>,
    filter: ((State, Payload) -> Bool)? = nil,
    map: ((State, Payload) -> Mapped)? = nil
) -> Event<Mapped> {
    linkBase(name: name, trigger: trigger, source: source, filter: filter, map: map)
}

@discardableResult
func link<Payload, State, Mapped>(
    name: String? = nil,
    trigger: Event<Payload>,
    source: Store<State>,
    filter: ((State, Payload) -> Bool)? = nil,
    map: ((State, Payload) -> Mapped)? = nil,
    target: Event<Mapped>
) -> Event<Mapped> {
    linkBase(name: name, trigger: trigger, source: source, filter: filter, map: map, target: target)
}

@discardableResult
func link<Payload, State, Mapped>(
    name: String? = nil,
    trigger: Event<Payload>,
    source: Store<State>,
    filter: ((State, Payload) -> Bool)? = nil,
    map: ((State, Payload) -> Mapped)? = nil,
    target: Store<Mapped>
) -> Event<Mapped> {
    linkBase(name: name, trigger: trigger, source: source, filter: filter, map: map, target: target)
}

@discardableResult
func link<Payload, State, Mapped, Done, Fail>(
    name: String? = nil,
    trigger: Event<Payload>,
    source: Store<State>,
    filter: ((State, Payload) -> Bool)? = nil,
    map: ((State, Payload) -> Mapped)? = nil,
    target: Effect<Mapped, Done, Fail>
) -> Event<Mapped> {
    linkBase(name: name, trigger: trigger, source: source, filter: filter, map: map, target: target)
}

// Link with source, but without map

@discardableResult
func link<Payload, State>(
    name: String? = nil,
    trigger: Event<Payload>,
    source: Store<State>,
    filter: ((State, Payload) -> Bool)? = nil
) -> Event<State> {
    linkBase(name: name, trigger: trigger, source: source, filter: filter)
}

@discardableResult
func link<Payload, State>(
    name: String? = nil,
    trigger: Event<Payload>,
    source: Store<State>,
    filter: ((State, Payload) -> Bool)? = nil,
    target: Event<State>
) -> Event<State> {
    linkBase(name: name, trigger: trigger, source: source, filter: filter, target: target)
}

@discardableResult
func link<Payload, State>(
    name: String? = nil,
    trigger: Event<Payload>,
    source: Store<State>,
    filter: ((State, Payload) -> Bool)? = nil,
    target: Store<State>
) -> Event<State> {
    linkBase(name: name, trigger: trigger, source: source, filter: filter, target: target)
}

@discardableResult
func link<Payload, State, Done, Fail>(
    name: String? = nil,
    trigger: Event<Payload>,
    source: Store<State>,
    filter: ((State, Payload) -> Bool)? = nil,
    target: Effect<State, Done, Fail>
) -> Event<State> {
    linkBase(name: name, trigger: trigger, source: source, filter: filter, target: target)
}

// Link without source

@discardableResult
func link<Payload, Mapped>(
    name: String? = nil,
    trigger: Event<Payload>,
    filter: ((Payload) -> Bool)? = nil,
    map: @escaping (Payload) -> Mapped
) -> Event<Mapped> {
    linkBase(name: name, trigger: trigger, filter: filter, map: map)
}

@discardableResult
func link<Payload, Mapped>(
    name: String? = nil,
    trigger: Event<Payload>,
    filter: ((Payload) -> Bool)? = nil,
    map: @escaping (Payload) -> Mapped,
    target: Event<Mapped>
) -> Event<Mapped> {
    linkBase(name: name, trigger: trigger, filter: filter, map: map, target: target)
}

@discardableResult
func link<Payload, Mapped>(
    name: String? = nil,
    trigger: Event<Payload>,
    filter: ((Payload) -> Bool)? = nil,
    map: @escaping (Payload) -> Mapped,
    target: Store<Mapped>
) -> Event<Mapped> {
    linkBase(name: name, trigger: trigger, filter: filter, map: map, target: target)
}

@discardableResult
func link<Payload, Mapped, Done, Fail>(
    name: String? = nil,
    trigger: Event<Payload>,
    filter: ((Payload) -> Bool)? = nil,
    map: @escaping (Payload) -> Mapped,
    target: Effect<Payload, Done, Fail>
) -> Event<Mapped> {
    linkBase(name: name, trigger: trigger, filter: filter, map: map, target: target)
}

// Link without source and map

@discardableResult
func link<Payload>(
    name: String? = nil,
    trigger: Event<Payload>,
    filter: ((Payload) -> Bool)? = nil
) -> Event<Payload> {
    linkBase(name: name, trigger: trigger, filter: filter)
}

@discardableResult
func link<Payload>(
    name: String? = nil,
    trigger: Event<Payload>,
    filter: ((Payload) -> Bool)? = nil,
    target: Event<Payload>
) -> Event<Payload> {
    linkBase(name: name, trigger: trigger, filter: filter, target: target)
}

@discardableResult
func link<Payload>(
    name: String? = nil,
    trigger: Event<Payload>,
    filter: ((Payload) -> Bool)? = nil,
    target: Store<Payload>
) -> Event<Payload> {
    linkBase(name: name, trigger: trigger, filter: filter, target: target)
}

@discardableResult
func link<Payload, Done, Fail>(
    name: String? = nil,
    trigger: Event<Payload>,
    filter: ((Payload) -> Bool)? = nil,
    target: Effect<Payload, Done, Fail>
) -> Event<Payload> {
    linkBase(name: name, trigger: trigger, filter: filter, target: target)
}
