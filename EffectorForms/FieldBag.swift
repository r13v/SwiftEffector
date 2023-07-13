import Combine
import Foundation

public protocol FieldBagProtocol: ObservableObject {
    associatedtype Value

    var error: String? { get }
    var value: Value { get set }
    var hasFocus: Bool { get set }
}

public final class FieldBag<T: Equatable, Root: FormValues>: FieldBagProtocol {
    // MARK: Lifecycle

    public init(_ field: EffectorFormField<T, Root>) {
        self.name = field.name
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

    public var name: String

    @Published
    public private(set) var error: String?

    @Published
    public var value: T {
        didSet {
            field.change(value)
        }
    }

    public var hasFocus: Bool = false {
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
