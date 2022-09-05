public typealias Validator<Value, Values> = (Value, Values) -> String?

public struct ValidationRule<Value, Values> {
    // MARK: Lifecycle

    public init(name: String, validator: @escaping Validator<Value, Values>) {
        self.name = name
        self.validator = validator
    }

    // MARK: Public

    public var name: String
    public var validator: Validator<Value, Values>
}

public enum ValidationEvent {
    case submit, blur, change
}

public struct ValidationError<Value: Equatable>: Equatable {
    public var rule: String
    public var value: Value
    public var errorText: String?
}
