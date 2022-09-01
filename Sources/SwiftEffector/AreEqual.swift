
public func areEqual<T>(lhs: T, rhs: T) -> Bool where T: Equatable {
    return lhs == rhs
}

public func areEqual<T>(_: T, _: T) -> Bool {
    return false
}
