import Foundation
import Effector
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

    @discardableResult
    public func register<Value: Equatable>(
        _ name: String,
        _ keyPath: KeyPath<Values, Value>,
        _ initialValue: @autoclosure @escaping () -> Value,
        _ rules: [ValidationRule<Value, Values>] = []
    ) -> EffectorFormField<Value, Values> {
        return register(.init(name: name, keyPath: keyPath, initialValue: initialValue(), rules: rules))
    }

    @discardableResult
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

    @discardableResult
    public func register<Value: Equatable>(_ fieldConfig: EffectorFormFieldConfig<Value, Values>) -> EffectorFormField<Value, Values> {
        let field = EffectorFormField(fieldConfig)

        isValidFlags.append(field.isValid)
        isDirtyFlags.append(field.isDirty)
        isTouchedFlags.append(field.isTouched)
        valuesStores.append(field.value.erased(name: field.name))

        bindChangeEvent(
            field: field,
            setForm: setForm,
            resetForm: resetForm,
            resetTouched: resetTouched,
            resetValues: resetValues
        )

        validationBindings.append { values in
            bindValidation(
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
        isDirty = contains(isDirtyFlags) { $0 }
        isTouched = contains(isTouchedFlags) { $0 }

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

        let isOk = allSatisfy([filter, isValid]) { $0 }

        sample(
            trigger: submitWithFormData,
            filter: isOk,
            target: submitted
        )

        sample(
            trigger: validateWithFormData,
            filter: isOk,
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

    private func checkRegisteredFields() {
        let formFieldsNames = Set(
            Mirror(reflecting: Values.self)
                .children
                .map { $0.label! }
        )

        if formFieldsNames != registeredFields {
            preconditionFailure("Registered fields missmatch.")
        }
    }
}

extension EffectorForm {
    struct Meta: Equatable {
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
