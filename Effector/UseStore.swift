import Foundation
import SwiftUI

@propertyWrapper
public struct UseStore<T>: DynamicProperty {
    // MARK: Lifecycle

    public init(_ store: Store<T>) {
        self.store = store
    }

    // MARK: Public

    public var wrappedValue: T {
        get {
            store.currentState
        }
        nonmutating set {
            store.setState(newValue)
        }
    }

    // MARK: Private

    @ObservedObject private var store: Store<T>
}
