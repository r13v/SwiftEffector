public func forward(from: [Unit], to: [Unit]) {
    createNode(
        name: "forward",
        priority: .child,
        from: from.map(\.graphite),
        to: to.map(\.graphite)
    )
}

public func forward(from: Unit, to: Unit) {
    forward(from: [from], to: [to])
}

public func forward(from: [Unit], to: Unit) {
    forward(from: from, to: [to])
}

public func forward(from: Unit, to: [Unit]) {
    forward(from: [from], to: to)
}
