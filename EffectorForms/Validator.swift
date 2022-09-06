import Foundation

public enum ValidationEvent {
    case submit, blur, change
}

public struct ValidationError<Value: Equatable>: Equatable {
    public var rule: String
    public var value: Value
    public var errorText: String?
}

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

let emailRegex = NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
// swiftlint:disable:next line_length
let urlRegex = NSPredicate(format: "SELF MATCHES %@", "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?")

public extension ValidationRule where Value == String {
    static func required(_ errorText: String? = nil) -> ValidationRule {
        .init(name: "required") { value, _ in
            value.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 ? nil : errorText ?? "Required"
        }
    }

    static func length(_ length: Int, _ errorText: String? = nil) -> ValidationRule {
        .init(name: "length") { value, _ in
            value.count == length
                ? nil
                : errorText ?? "Must be exactly \(length) characters"
        }
    }

    static func min(_ min: Int, _ errorText: String? = nil) -> ValidationRule {
        .init(name: "min") { value, _ in
            value.count >= min
                ? nil
                : errorText ?? "Must be at least \(min) characters"
        }
    }

    static func max(_ max: Int, _ errorText: String? = nil) -> ValidationRule {
        .init(name: "max") { value, _ in
            value.count <= max
                ? nil
                : errorText ?? "Must be at most \(max) characters"
        }
    }

    static func url(_ errorText: String? = nil) -> ValidationRule {
        .init(name: "url") { value, _ in
            urlRegex.evaluate(with: value)
                ? nil
                : errorText ?? "Must be a valid URL"
        }
    }

    static func email(_ errorText: String? = nil) -> ValidationRule {
        .init(name: "email") { value, _ in
            emailRegex.evaluate(with: value)
                ? nil
                : errorText ?? "Must be a valid email"
        }
    }

    static func matches(_ regex: NSRegularExpression, _ errorText: String? = nil) -> ValidationRule {
        .init(name: "matches") { value, _ in
            regex.firstMatch(in: value, range: NSRange(location: 0, length: value.utf16.count)) != nil
                ? nil
                : errorText ?? "Must be a valid email"
        }
    }

    static func trim(_ errorText: String? = nil) -> ValidationRule {
        .init(name: "trim") { value, _ in
            value.trimmingCharacters(in: .whitespacesAndNewlines).count == value.count
                ? nil
                : errorText ?? "Must be a trimmed string"
        }
    }
}

public extension ValidationRule where Value == Int {
    static func min(_ min: Int, _ errorText: String? = nil) -> ValidationRule {
        .init(name: "min") { value, _ in
            value >= min ? nil : errorText ?? "Must be greater than or equal to \(min)"
        }
    }

    static func max(_ max: Int, _ errorText: String? = nil) -> ValidationRule {
        .init(name: "max") { value, _ in
            value <= max ? nil : errorText ?? "Must be less than or equal to \(max)"
        }
    }

    static func moreThan(_ min: Int, _ errorText: String? = nil) -> ValidationRule {
        .init(name: "moreThan") { value, _ in
            value > min ? nil : errorText ?? "Must be greater than \(min)"
        }
    }

    static func lessThan(_ max: Int, _ errorText: String? = nil) -> ValidationRule {
        .init(name: "lessThan") { value, _ in
            value < max ? nil : errorText ?? "Must be less than \(max)"
        }
    }
}
