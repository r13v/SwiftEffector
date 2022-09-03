public func forward(from: [Unit], to: [Unit]) {
    createNode(
        name: "forward",
        priority: .child,
        from: from,
        to: to
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
