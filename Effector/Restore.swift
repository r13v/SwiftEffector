public func restore<T>(_ event: Event<T>, _ initial: T) -> Store<T> {
    let store = Store(name: "\(event.name):restore", initial)

    store.on(event) { _, payload in payload }

    return store
}

public func restore<T>(_ event: Event<T>) -> Store<T?> {
    let store = Store<T?>(name: "\(event.name):restore", nil)

    store.on(event) { _, payload in payload }

    return store
}
