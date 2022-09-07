import Effector
import Foundation
import SwiftUI

public typealias FormValues = Codable & Equatable

public final class EffectorForm<Values: FormValues> {
    // MARK: Lifecycle

    public init(
        validateOn: Set<ValidationEvent> = Set([.submit]),
        filter: Store<Bool> = Store(true)
    ) {
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
    public func field<Value: Equatable>(
        name: String,
        keyPath: KeyPath<Values, Value>,
        initialValue: @autoclosure @escaping () -> Value,
        rules: [ValidationRule<Value, Values>] = []
    ) -> EffectorFormField<Value, Values> {
        EffectorFormField(
            .init(name: name, keyPath: keyPath, initialValue: initialValue(), rules: rules)
        )
    }

    @discardableResult
    public func field<Value: Equatable>(
        name: String,
        keyPath: KeyPath<Values, Value>,
        initialValue: @autoclosure @escaping () -> Value,
        validator: Validator<Value, Values>?
    ) -> EffectorFormField<Value, Values> {
        EffectorFormField(
            .init(
                name: name,
                keyPath: keyPath,
                initialValue: initialValue(),
                rules: validator != nil ? [.init(name: name, validator: validator!)] : []
            )
        )
    }

    @discardableResult
    public func field<Value: Equatable>(
        name: String,
        keyPath: KeyPath<Values, Value>,
        initialValue: @autoclosure @escaping () -> Value,
        rule: ValidationRule<Value, Values>?
    ) -> EffectorFormField<Value, Values> {
        EffectorFormField(
            .init(
                name: name,
                keyPath: keyPath,
                initialValue: initialValue(),
                rules: rule != nil ? [rule!] : []
            )
        )
    }

    @discardableResult
    public func field<Value: Equatable>(
        config: EffectorFormFieldConfig<Value, Values>
    ) -> EffectorFormField<Value, Values> {
        EffectorFormField(config)
    }

    @discardableResult
    public func register<Value: Equatable>(
        field: EffectorFormField<Value, Values>
    ) -> EffectorFormField<Value, Values> {
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

    public func build() {
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
    }

    // MARK: Internal

    var validateOn: Set<ValidationEvent>
    var filter: Store<Bool>

    // MARK: Private

    private var validationBindings = [(values: Store<Values>) -> Void]()

    private var isValidFlags = [Store<Bool>]()
    private var isDirtyFlags = [Store<Bool>]()
    private var isTouchedFlags = [Store<Bool>]()
    private var valuesStores = [Store<Any>]()
}

public extension EffectorForm {
    struct Meta: Equatable {
        public var isValid: Bool
        public var isDirty: Bool
        public var isTouched: Bool
    }
}

public struct EffectorFormConfig<Values> {
    public var fields: [EffectorFormFieldConfig<Any, Values>] = []
    public var validateOn: Set<ValidationEvent> = Set([.submit])
    public var filter: Store<Bool> = Store(true)
}
