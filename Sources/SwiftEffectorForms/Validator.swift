struct ValidationRule<Value, Values> {
    var name: String
    var errorText: String?
    var validator: Validator<Value, Values>
}

enum Validator<Value, Values> {
    case bool((Value, Values) -> Bool)
    case withMessage((Value, Values) -> ValidationResult)
}

struct ValidationResult {
    var isValid: Bool
    var errorText: String?
}

enum ValidationEvent {
    case submit, blur, change
}

struct ValidationError<Value> {
    var rule: String
    var value: Value
    var errorText: String?
}
