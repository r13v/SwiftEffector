import SwiftEffector

final class EFormField<Value, Values> {
    // MARK: Lifecycle

    init(_ config: Config<Value, Values>) {
        self.config = config

        let initialValue = config.initialValue()

        self.name = config.name
        self.value = Store(initialValue)

        let errors = Store<[ValidationError<Value>]>([])
        let firstError = errors.map { $0.isEmpty ? nil : $0[0] }

        let isValid = firstError.map { $0 == nil }

        let isDirty = value.map { areEqual($0, initialValue) }

        let isTouched = Store(false)

        self.errors = errors
        self.firstError = firstError
        self.isValid = isValid
        self.isDirty = isDirty
        self.isTouched = isTouched

        self.field = combine(value, errors, firstError, isValid, isDirty, isTouched) {
            value, errors, firstError, isValid, isDirty, isTouched in
            FieldData(
                value: value,
                errors: errors,
                firstError: firstError,
                isValid: isValid,
                isDirty: isDirty,
                isTouched: isTouched
            )
        }
    }

    // MARK: Internal

    var config: Config<Value, Values>
    var name: String
    var value: Store<Value>
    var errors: Store<[ValidationError<Value>]>
    var firstError: Store<ValidationError<Value>?>

    var isValid: Store<Bool>
    var isDirty: Store<Bool>
    var isTouched: Store<Bool>

    var field: Store<FieldData<Value>>

    var change = Event<Value>()
    var changed = Event<Value>()
    var blur = Event<Void>()
    var addError = Event<FormFieldError>()
    var validate = Event<Void>()
    var reset = Event<Void>()
    var setValue = Event<Value>()
    var resetErrors = Event<Void>()
    var resetValue = Event<Void>()
    var filter = Store(true)
}

extension EFormField {
    struct FieldData<Value> {
        var value: Value
        var errors: [ValidationError<Value>]
        var firstError: ValidationError<Value>?

        var isValid: Bool
        var isDirty: Bool
        var isTouched: Bool
    }
}

extension EFormField {
    struct FormFieldError {
        var rule: String
        var errorText: String?
    }
}

extension EFormField {
    struct Config<Value, Values> {
        // MARK: Lifecycle

        internal init(
            name: String,
            initialValue: @autoclosure @escaping () -> Value,
            rules: [ValidationRule<Value, Values>] = [],
            validateOn: Set<ValidationEvent> = Set([.submit])
        ) {
            self.name = name
            self.initialValue = initialValue
            self.rules = rules
            self.validateOn = validateOn
        }

        // MARK: Internal

        var name: String
        var initialValue: () -> Value
        var rules: [ValidationRule<Value, Values>] = []
        var validateOn: Set<ValidationEvent> = Set([.submit])
    }
}
