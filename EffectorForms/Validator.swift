public typealias Validator<Value, Values> = (Value, Values) -> String?

public struct ValidationRule<Value, Values> {
    var name: String
    var validator: Validator<Value, Values>
}

public enum ValidationEvent {
    case submit, blur, change
}

public struct ValidationError<Value: Equatable>: Equatable {
    var rule: String
    var value: Value
    var errorText: String?
}
