import Foundation
import SwiftEffector
import SwiftUI

final class EffectorForm<Values: Codable> {
    // MARK: Lifecycle

    init(validateOn: Set<ValidationEvent> = Set([.submit]), filter: Store<Bool> = Store(true)) {
        self.validateOn = validateOn
        self.filter = filter
    }

    // MARK: Public

    public var values: Store<Values>!

    public var isValid: Store<Bool>!
    public var isDirty: Store<Bool>!
    public var isTouched: Store<Bool>!
    public var meta: Store<Meta>!

    public var submit = Event<Void>()
    public var validate = Event<Void>()
    public var resetForm = Event<Void>()
    public var setForm = Event<Values>()

    public var resetTouched = Event<Void>()
    public var resetValues = Event<Void>()
    public var resetErrors = Event<Void>()

    public var submitted = Event<Values>()
    public var validated = Event<Values>()

    public func register<Value: Equatable>(
        _ name: String,
        _ keyPath: KeyPath<Values, Value>,
        _ initialValue: @autoclosure @escaping () -> Value,
        _ rules: [ValidationRule<Value, Values>] = []
    ) -> EffectorFormField<Value, Values> {
        return register(.init(name: name, keyPath: keyPath, initialValue: initialValue(), rules: rules))
    }

    public func register<Value: Equatable>(
        _ name: String,
        _ keyPath: KeyPath<Values, Value>,
        _ initialValue: @autoclosure @escaping () -> Value,
        _ rule: Validator<Value, Values>?
    ) -> EffectorFormField<Value, Values> {
        return register(
            .init(
                name: name,
                keyPath: keyPath,
                initialValue: initialValue(),
                rules: rule != nil ? [.init(name: name, validator: rule!)] : []
            )
        )
    }

    public func register<Value: Equatable>(_ fieldConfig: EffectorFormFieldConfig<Value, Values>) -> EffectorFormField<Value, Values> {
        let field = EffectorFormField(fieldConfig)

        isValidFlags.append(field.isValid)
        isDirtyFlags.append(field.isDirty)
        isTouchedFlags.append(field.isTouched)
        valuesStores.append(field.value.map(name: field.name) { $0 as Any })

        Self.bindChangeEvent(
            field: field,
            setForm: setForm,
            resetForm: resetForm,
            resetTouched: resetTouched,
            resetValues: resetValues
        )

        validationBindings.append { values in
            Self.bindValidation(
                values: values,
                validateFormEvent: self.validate,
                submitEvent: self.submit,
                resetFormEvent: self.resetForm,
                resetValues: self.resetValues,
                resetErrorsFormEvent: self.resetErrors,
                field: field,
                formValidationEvents: self.validateOn
            )
        }

        return field
    }

    @discardableResult
    public func build() -> Self {
        checkRegisteredFields()

        isValid = allSatisfy(isValidFlags) { $0 }
        isDirty = allSatisfy(isDirtyFlags) { $0 }
        isTouched = allSatisfy(isTouchedFlags) { $0 }

        meta = combine(isValid, isDirty, isTouched) { isValid, isDirty, isTouched in
            Meta(isValid: isValid, isDirty: isDirty, isTouched: isTouched)
        }

        values = combine(valuesStores)

        validationBindings.forEach { bind in bind(values) }
        validationBindings = []

        let submitWithFormData = sample(
            trigger: submit,
            source: values
        )

        let validateWithFormData = sample(
            trigger: validate,
            source: values
        )

        sample(
            trigger: submitWithFormData,
            filter: isValid,
            target: submitted
        )

        sample(
            trigger: validateWithFormData,
            filter: isValid,
            target: validated
        )

        return self
    }

    // MARK: Internal

    var validateOn: Set<ValidationEvent>
    var filter: Store<Bool>

    // MARK: Private

    private var registeredFields = Set<String>()
    private var validationBindings = [(values: Store<Values>) -> Void]()

    private var isValidFlags = [Store<Bool>]()
    private var isDirtyFlags = [Store<Bool>]()
    private var isTouchedFlags = [Store<Bool>]()
    private var valuesStores = [Store<Any>]()

    private static func bindValidation<T>(
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

    private static func combineValidationRules<Value>(
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

    private static func bindChangeEvent<T>(
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

    private func checkRegisteredFields() {
        let formFieldsNames = Set(Mirror(reflecting: Values.self).children.map { $0.label! })

        if formFieldsNames != registeredFields {
            preconditionFailure("Registered fields missmatch.")
        }
    }
}

extension EffectorForm {
    struct Meta {
        var isValid: Bool
        var isDirty: Bool
        var isTouched: Bool
    }
}

struct EffectorFormConfig<Values> {
    var fields: [EffectorFormFieldConfig<Any, Values>] = []
    var validateOn: Set<ValidationEvent> = Set([.submit])
    var filter: Store<Bool> = Store(true)
}
