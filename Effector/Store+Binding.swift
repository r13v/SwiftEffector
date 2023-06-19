import SwiftUI

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
