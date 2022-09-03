public func merge<Payload>(_ events: Event<Payload>...) -> Event<Payload> {
    let event = Event<Payload>(name: "merge", isDerived: true)

    createNode(
        name: "merge",
        kind: .event,
        priority: .effect,
        from: events,
        to: [event]
    )

    return event
}
