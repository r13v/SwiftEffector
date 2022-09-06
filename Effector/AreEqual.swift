public func areEqual<T>(_ lhs: T, _ rhs: T) -> Bool where T: Equatable {
    return lhs == rhs
}

public func areEqual<T>(_ lhs: T, _ rhs: T) -> Bool where T: AnyObject {
    return lhs === rhs
}

public func areEqual<T>(_: T, _: T) -> Bool {
    return false
}
