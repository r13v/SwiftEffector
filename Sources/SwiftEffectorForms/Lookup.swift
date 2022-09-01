import Foundation

@dynamicMemberLookup
class Lookup<Value> {
    // MARK: Lifecycle

    init(_ dict: [String: Any]) {
        self.dict = dict
    }

    // MARK: Internal

    fileprivate(set) var dict: [String: Any]

    subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
        dict[keyPath.asString] as! T
    }
}
