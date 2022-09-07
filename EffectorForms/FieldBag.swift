import Foundation
import Combine

public final class FieldBag<T: Equatable, Root: FormValues>: ObservableObject {
    // MARK: Lifecycle

    public init(_ field: EffectorFormField<T, Root>) {
        self.field = field
        self.value = field.value.getState()
        self.error = field.firstError.currentState?.errorText

        field.firstError.$currentState
            .sink { error in
                self.error = error?.errorText
            }
            .store(in: &cancelables)
    }

    // MARK: Public

    @Published
    public var value: T {
        didSet {
            field.change(value)
        }
    }

    public func change(_ newValue: T) {
        field.change(newValue)
    }

    // MARK: Internal

    @Published
    private(set) var error: String?

    var hasFocus: Bool = false {
        didSet {
            if !field.isTouched.getState() {
                field.isTouched.setState(true)
            }
        }
    }

    // MARK: Private

    private var cancelables = Set<AnyCancellable>()
    private let field: EffectorFormField<T, Root>
}
