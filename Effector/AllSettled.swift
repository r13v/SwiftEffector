func allSettled(event: Event<Void>) async {
    await allSettled(event: event, payload: ())
}

func allSettled<Payload>(event: Event<Payload>, payload: Payload) async {
    return await withCheckedContinuation { continuation in
        let step: (Any) -> Void = { _ in continuation.resume(returning: ()) }

        createNode(
            name: "allSettled",
            priority: .effect,
            from: [event.graphite],
            seq: [.compute("allSettled", eraseCompute(step))]
        )

        event(payload)
    }
}
