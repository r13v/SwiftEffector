import Foundation
import SwiftUI

@propertyWrapper
public struct Use<T>: DynamicProperty {
    // MARK: Lifecycle

    public init(_ store: Store<T>, _ change: Event<T>? = nil) {
        self.store = store
        self.change = change
    }

    // MARK: Public

    public var wrappedValue: T {
        get {
            store.currentState
        }
        nonmutating set {
            if let change = change {
                change(newValue)
            } else {
                store.setState(newValue)
            }
        }
    }

    // MARK: Internal

    var change: Event<T>?

    // MARK: Private

    @ObservedObject
    private var store: Store<T>
}

public extension Store {
    func binding(_ change: Event<State>? = nil) -> Binding<State> {
        Binding {
            self.currentState
        } set: { value in
            if let change {
                change(value)
            } else {
                self.setState(value)
            }
        }
    }
}
