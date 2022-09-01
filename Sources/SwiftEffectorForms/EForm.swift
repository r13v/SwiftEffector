import Foundation
import SwiftEffector
import SwiftUI

protocol FormValues: InitializableFromDict, CaseIterable {
    subscript<T>(_ key: String) -> T { get set }
}

final class EForm<Values: FormValues> {
    // MARK: Lifecycle

    init(config: Config<Values>) {
        var fields = [String: EFormField<Any, Values>]()

        self.submit = Event<Void>()
        self.validate = Event<Void>()
        self.resetForm = Event<Void>()
        self.setForm = Event<Values>()

        self.resetTouched = Event<Void>()
        self.resetValues = Event<Void>()
        self.resetErrors = Event<Void>()

        self.submitted = Event<Values>()
        self.validated = Event<Values>()

        var isValidFlags = [Store<Bool>]()
        var isDirtyFlags = [Store<Bool>]()
        var isTouchedFlags = [Store<Bool>]()

        var values = [Store<Any>]()

        for fieldConfig in config.fields {
            let field = EFormField(fieldConfig)

            fields[field.name] = field

            isValidFlags.append(field.isValid)
            isDirtyFlags.append(field.isDirty)
            isTouchedFlags.append(field.isTouched)
            values.append(field.value as Store<Any>)
        }

        let isValid = allSatisfy(isValidFlags) { $0 }
        let isDirty = allSatisfy(isDirtyFlags) { $0 }
        let isTouched = allSatisfy(isTouchedFlags) { $0 }

        let meta = combine(isValid, isDirty, isTouched) { isValid, isDirty, isTouched in
            Meta(isValid: isValid, isDirty: isDirty, isTouched: isTouched)
        }

        self.meta = meta

        self.values = combine(values)
        self.fields = fields
        self.isValid = isValid
        self.isDirty = isDirty
        self.isTouched = isTouched

        let submitWithFormData = sample(
            trigger: submit,
            source: self.values
        )

        let validateWithFormData = sample(
            trigger: validate,
            source: self.values
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

        for (_, field) in fields {
            Self.bindChangeEvent(
                field: field,
                setForm: setForm,
                resetForm: resetForm,
                resetTouched: resetTouched,
                resetValues: resetValues
            )

            Self.bindValidation(
                values: self.values,
                validateFormEvent: validate,
                submitEvent: submit,
                resetFormEvent: resetForm,
                resetValues: resetValues,
                resetErrorsFormEvent: resetErrors,
                field: field,
                formValidationEvents: config.validateOn
            )
        }
    }

    // MARK: Internal

    var values: Store<Values>

    var fields: [String: EFormField<Any, Values>]

    var isValid: Store<Bool>
    var isDirty: Store<Bool>
    var isTouched: Store<Bool>
    var meta: Store<Meta>

    var submit: Event<Void>
    var validate: Event<Void>
    var resetForm: Event<Void>
    var setForm: Event<Values>

    var resetTouched: Event<Void>
    var resetValues: Event<Void>
    var resetErrors: Event<Void>

    var submitted: Event<Values>
    var validated: Event<Values>

    // MARK: Private

    private static func bindValidation(
        values: Store<Values>,
        validateFormEvent: Event<Void>,
        submitEvent: Event<Void>,
        resetFormEvent: Event<Void>,
        resetValues: Event<Void>,
        resetErrorsFormEvent: Event<Void>,
        field: EFormField<Any, Values>,
        formValidationEvents: Set<ValidationEvent>
    ) {
        let fieldConfig = field.config

        let validator = combineValidationRules(fieldConfig.rules)
        let validateOn = formValidationEvents.union(fieldConfig.validateOn)

        var validationEvents = [Event<(Any, Values)>]()

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
                    switch rule.validator {
                    case .bool(let fn):
                        if fn(value, values) {
                            errors.append(
                                ValidationError(rule: rule.name,
                                                value: value,
                                                errorText: rule.errorText)
                            )
                        }

                    case .withMessage(let fn):
                        let result = fn(value, values)

                        if !result.isValid {
                            errors.append(
                                ValidationError(
                                    rule: rule.name,
                                    value: value,
                                    errorText: result.errorText
                                )
                            )
                        }
                    }
                }
                return errors
            }

        return validator
    }

    private static func bindChangeEvent(
        field: EFormField<Any, Values>,
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
            .on(setForm) { _, values in values[field.name] } // todo
            .reset([field.reset, field.resetValue, resetValues, resetForm])
    }
}

extension EForm {
    struct Meta {
        var isValid: Bool
        var isDirty: Bool
        var isTouched: Bool
    }
}

extension EForm {
    struct Config<Values> {
        var fields: [EFormField<Any, Values>.Config<Any, Values>] = []
        var validateOn: Set<ValidationEvent> = Set([.submit])
        var filter: Store<Bool> = Store(true)
    }
}
