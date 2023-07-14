import SwiftUI

public extension View {
    func gate<Value>(_ gate: Gate<Value>, value: Value) -> some View {
        self
            .background {
                gate(value)
            }
    }

    func gate(_ gate: Gate<Void>) -> some View {
        self.gate(gate, value: ())
    }
}
