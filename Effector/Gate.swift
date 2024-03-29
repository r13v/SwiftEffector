import SwiftUI

public struct Gate<Value> {
    // MARK: Lifecycle

    public init() {
        status
            .on(open) { _, _ in true }
            .on(close) { _, _ in false }

        state
            .on(open) { _, value in value }
            .on(close) { _, _ in nil }
    }

    // MARK: Public

    public let state = Store<Value?>(nil)
    public let status = Store(false)
    public let open = Event<Value>()
    public let close = Event<Void>()

    public func callAsFunction(_ value: Value) -> some View {
        state.setState(value)

        return Rectangle()
            .hidden()
            .onAppear {
                open(value)
            }
            .onDisappear {
                close()
            }
    }
}

public extension Gate where Value == Void {
    func callAsFunction() -> some View {
        callAsFunction(())
    }
}
