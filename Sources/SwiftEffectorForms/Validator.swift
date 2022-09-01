public struct ValidationRule<Value, Values> {
    var name: String
    var validator: (Value, Values) -> String?
}

public enum ValidationEvent {
    case submit, blur, change
}

public struct ValidationError<Value> {
    var rule: String
    var value: Value
    var errorText: String?
}
