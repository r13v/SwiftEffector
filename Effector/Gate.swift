import SwiftUI

public struct Gate<T> {
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

    public let state = Store<T?>(nil)
    public let status = Store(false)
    public let open = Event<T>()
    public let close = Event<Void>()

    public func view(_ value: T) -> some View {
        Rectangle()
            .hidden()
            .onAppear {
                open(value)
            }
            .onDisappear {
                close()
            }
    }
}

public extension Gate where T == Void {
    func view() -> some View {
        view(())
    }
}
