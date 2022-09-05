import Effector
import Foundation
import SwiftUI

public final class EffectorFormField<Value: Equatable, Values: Equatable> {
    // MARK: Lifecycle

    public init(_ config: EffectorFormFieldConfig<Value, Values>) {
        self.config = config
        self.name = config.name
        self.filter = config.filter

        let initialValue = config.initialValue()

        self.value = Store(initialValue)

        let errors = Store<[ValidationError<Value>]>([])
        let firstError = errors.map { $0.isEmpty ? nil : $0[0] }

        let isValid = firstError.map { $0 == nil }

        let isDirty = value.map { !areEqual($0, initialValue) }

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

        isTouched.reset(resetTouched)
    }

    // MARK: Public

    public var name: String
    public var value: Store<Value>
    public var errors: Store<[ValidationError<Value>]>
    public var firstError: Store<ValidationError<Value>?>

    public var isValid: Store<Bool>
    public var isDirty: Store<Bool>
    public var isTouched: Store<Bool>

    public var field: Store<FieldData<Value>>

    public var change = Event<Value>()
    public var changed = Event<Value>()
    public var blur = Event<Void>()
    public var addError = Event<FormFieldError>()
    public var validate = Event<Void>()
    public var reset = Event<Void>()
    public var setValue = Event<Value>()
    public var resetErrors = Event<Void>()
    public var resetTouched = Event<Void>()
    public var resetValue = Event<Void>()
    public var filter: Store<Bool>

    public private(set) lazy var binding: Binding<Value> = Binding { self.value.currentState } set: { self.change($0) }

    // MARK: Internal

    var config: EffectorFormFieldConfig<Value, Values>
}

public extension EffectorFormField {
    struct FieldData<Value: Equatable> {
        public var value: Value
        public var errors: [ValidationError<Value>]
        public var firstError: ValidationError<Value>?

        public var isValid: Bool
        public var isDirty: Bool
        public var isTouched: Bool
    }
}

public struct EffectorFormFieldConfig<Value, Values> {
    // MARK: Lifecycle

    public init(
        name: String,
        keyPath: KeyPath<Values, Value>,
        initialValue: @autoclosure @escaping () -> Value,
        rules: [ValidationRule<Value, Values>] = [],
        validateOn: Set<ValidationEvent> = Set([.submit]),
        filter: Store<Bool> = Store(true)
    ) {
        self.name = name
        self.keyPath = keyPath
        self.initialValue = initialValue
        self.rules = rules
        self.validateOn = validateOn
        self.filter = filter
    }

    // MARK: Internal

    var name: String
    var keyPath: KeyPath<Values, Value>
    var initialValue: () -> Value
    var rules: [ValidationRule<Value, Values>] = []
    var validateOn: Set<ValidationEvent> = Set([.submit])
    var filter: Store<Bool>
}

public struct FormFieldError {
    // MARK: Lifecycle

    public init(rule: String, errorText: String?) {
        self.rule = rule
        self.errorText = errorText
    }

    // MARK: Public

    public var rule: String
    public var errorText: String?
}

func bindChangeEvent<Values, T>(
    field: EffectorFormField<T, Values>,
    setForm: Event<Values>,
    resetForm: Event<Void>,
    resetTouched: Event<Void>,
    resetValues: Event<Void>
) {
    field.isTouched
        .on(field.changed) { _, _ in true }
        .reset([field.reset, resetForm, resetTouched])

    sample(
        trigger: field.change,
        filter: field.filter,
        target: field.changed
    )

    field.value
        .on(field.changed) { _, value in value }
        .on(setForm) { state, values in
            let mirror = Mirror(reflecting: values)

            for child in mirror.children {
                if child.label == field.name {
                    return child.value as! T
                }
            }

            return state
        }
        .reset([field.reset, field.resetValue, resetValues, resetForm])
}

func bindValidation<T, Values>(
    values: Store<Values>,
    validateFormEvent: Event<Void>,
    submitEvent: Event<Void>,
    resetFormEvent: Event<Void>,
    resetValues: Event<Void>,
    resetErrorsFormEvent: Event<Void>,
    field: EffectorFormField<T, Values>,
    formValidationEvents: Set<ValidationEvent>
) {
    let fieldConfig = field.config

    let validator = combineValidationRules(fieldConfig.rules)
    let validateOn = formValidationEvents.union(fieldConfig.validateOn)

    var validationEvents = [Event<(T, Values)>]()

    let validationData = combine(field.value, values) { value, values in (value, values) }

    if validateOn.contains(.submit) {
        let trigger = sample(trigger: submitEvent, source: validationData)
        validationEvents.append(trigger)
    }

    if validateOn.contains(.blur) {
        let trigger = sample(trigger: field.blur, source: validationData)
        validationEvents.append(trigger)
    }

    if validateOn.contains(.change) {
        let changed = merge(field.changed.map { _ in }, field.resetValue, resetValues)
        let trigger = sample(trigger: changed, source: validationData)
        validationEvents.append(trigger)
    }

    validationEvents.append(
        sample(trigger: field.validate, source: validationData)
    )

    validationEvents.append(
        sample(trigger: validateFormEvent, source: validationData)
    )

    let addErrorWithValue = sample(
        trigger: field.addError,
        source: field.value,
        map: { value, error in
            ValidationError(rule: error.rule, value: value, errorText: error.errorText)
        }
    )

    field.errors
        .on(validationEvents) { _, data in validator(data.0, data.1) }
        .on(addErrorWithValue) { list, error in list + [error] }
        .reset([field.resetErrors, resetFormEvent, field.reset, resetErrorsFormEvent])

    if !validateOn.contains(.change) {
        field.errors.reset(field.changed)
    }
}

func combineValidationRules<Value, Values>(
    _ rules: [ValidationRule<Value, Values>]
) -> (Value, Values) -> [ValidationError<Value>] {
    let validator: (_ value: Value, _ values: Values) -> [ValidationError<Value>] =
        { value, values in
            var errors = [ValidationError<Value>]()

            for rule in rules {
                if let errorText = rule.validator(value, values) {
                    errors.append(
                        ValidationError(
                            rule: rule.name,
                            value: value,
                            errorText: errorText
                        )
                    )
                }
            }
            return errors
        }

    return validator
}
