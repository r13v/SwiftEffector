// swiftlint:disable file_length
import Effector
@testable import EffectorForms
import XCTest

struct SignInForm: FormValues {
    var email: String
    var password: String
}

struct SignUpForm: FormValues {
    var email: String
    var password: String
    var confirm: String
}

struct Email {
    enum EmailParseError: Error, LocalizedError {
        case noAtSymbol

        // MARK: Internal

        var errorDescription: String? {
            switch self {
            case .noAtSymbol: return "invalid email"
            }
        }
    }

    private(set) var value: String

    static func parse(_ input: String) -> Result<Email, EmailParseError> {
        if !input.contains("@") {
            return .failure(EmailParseError.noAtSymbol)
        }

        return .success(Email(value: input))
    }
}

func minLength<Values>(_ min: Int) -> (_ value: String, _: Values) -> String? {
    { value, _ in value.count >= min ? nil : "Minimum \(min) symbols" }
}

func validEmail<Values>(_ value: String, _: Values) -> String? {
    Email.parse(value).errorString
}

func makeEmailValidationRule<Values>() -> ValidationRule<String, Values> {
    .init(name: "email", validator: validEmail)
}

func requiredString<Values>(_ value: String, _: Values) -> String? {
    value.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 ? nil : "Required"
}

// swiftlint:disable:next type_body_length
final class FormTests: XCTestCase {
    // swiftlint:disable:next function_body_length
    func testSignInForm() async throws {
        let form = EffectorForm<SignInForm>()
        let email = form.field(
            keyPath: \.email,
            initialValue: "",
            validator: validEmail
        )
        let password = form.field(
            keyPath: \.password,
            initialValue: "",
            rules: [.init(name: "minLength", validator: minLength(4))]
        )

        form.register(field: email)
        form.register(field: password)
        form.build()

        var formSubmitted = false

        form.submitted.watch { _ in formSubmitted = true }

        XCTAssertFalse(formSubmitted)

        email.change("invalid")

        XCTAssertEqual(email.errors.getState(), [])
        XCTAssertEqual(password.errors.getState(), [])
        XCTAssert(form.isValid.getState())
        XCTAssertEqual(form.values.getState(), SignInForm(email: "invalid", password: ""))

        form.submit()

        XCTAssertFalse(form.isValid.getState())
        XCTAssertFalse(formSubmitted)
        XCTAssertEqual(
            email.firstError.getState()!,
            ValidationError(rule: "email", value: "invalid", errorText: "invalid email")
        )
        XCTAssertEqual(
            password.firstError.getState()!,
            ValidationError(rule: "minLength", value: "", errorText: "Minimum 4 symbols")
        )

        email.change("test")

        XCTAssertNil(email.firstError.getState())
        XCTAssertFalse(form.isValid.getState())

        form.submit()

        XCTAssertFalse(form.isValid.getState())
        XCTAssertEqual(
            email.firstError.getState()!,
            ValidationError(rule: "email", value: "test", errorText: "invalid email")
        )

        email.change("test@gmail.com")
        password.change("1234")

        XCTAssert(form.isValid.getState())

        form.submit()

        XCTAssertNil(email.firstError.getState())
        XCTAssertNil(password.firstError.getState())
        XCTAssert(form.isValid.getState())
        XCTAssertEqual(form.values.getState(), SignInForm(email: "test@gmail.com", password: "1234"))
        XCTAssert(formSubmitted)
    }

    // swiftlint:disable:next function_body_length
    func testSignUpForm() async throws {
        let form = EffectorForm<SignUpForm>(validateOn: Set([.submit]))

        let email = form.field(
            config: .init(
                keyPath: \.email,
                initialValue: "",
                rules: [.init(name: "email", validator: validEmail)],
                validateOn: Set([.blur])
            )
        )

        let password = form.field(
            keyPath: \.password,
            initialValue: "",
            rules: [
                .init(name: "required", validator: requiredString),
                .init(name: "minLength", validator: minLength(3))
            ]
        )

        let confirm = form.field(
            config: .init(
                keyPath: \.confirm,
                initialValue: "",
                rules: [
                    .init(
                        name: "equal",
                        validator: { value, values in
                            value == values.password ? nil : "Should be equal"
                        }
                    )
                ],
                validateOn: Set([.change])
            )
        )

        form.register(field: email)
        form.register(field: password)
        form.register(field: confirm)

        form.build()

        var formSubmitted = false

        form.submitted.watch { _ in formSubmitted = true }

        password.change("123")
        XCTAssert(form.isValid.getState())

        email.change("test")
        XCTAssert(form.isValid.getState())

        email.blur()
        XCTAssertFalse(form.isValid.getState())

        email.change("test@example.com")
        XCTAssert(form.isValid.getState())

        password.change("123")
        XCTAssert(form.isValid.getState())

        confirm.change("12")
        XCTAssertFalse(form.isValid.getState())

        confirm.change("123")

        XCTAssert(form.isValid.getState())
        XCTAssertFalse(formSubmitted)

        form.submit()
        XCTAssert(form.isValid.getState())
        XCTAssertEqual(form.values.getState(), SignUpForm(email: "test@example.com", password: "123", confirm: "123"))

        XCTAssert(formSubmitted)
    }

    func testRegisterFieldWithValidationRules() async throws {
        let form = EffectorForm<SignInForm>()

        let email = form.field(
            keyPath: \.email,
            initialValue: "",
            rule: .email()
        )
        let password = form.field(
            keyPath: \.password,
            initialValue: "",
            rule: .min(6)
        )

        form.register(field: email)
        form.register(field: password)

        form.build()
    }

    func testSetForm() async throws {
        let form = EffectorForm<SignInForm>()
        let email = form.field(
            keyPath: \.email,
            initialValue: "",
            validator: validEmail
        )
        let password = form.field(
            keyPath: \.password,
            initialValue: "",
            validator: requiredString
        )

        form.register(field: email)
        form.register(field: password)
        form.build()

        let filled = SignInForm(email: "test@example.com", password: "123")

        form.setForm(filled)

        XCTAssertEqual(form.values.getState(), filled)
    }

    func testFilter() async throws {
        enum SignInError: Error {
            case invalidCredentials
        }

        let signInFx = Effect<SignInForm, Bool, SignInError> { values in
            if values.email == "test@example.com" {
                throw SignInError.invalidCredentials
            }

            return true
        }

        let serverError = Store(false)

        serverError.on(signInFx.fail) { _, _ in true }

        let form = EffectorForm<SignInForm>(filter: serverError.map { !$0 })

        let email = form.field(keyPath: \.email, initialValue: "", validator: validEmail)
        let password = form.field(
            keyPath: \.password,
            initialValue: "",
            validator: requiredString
        )

        form.register(field: email)
        form.register(field: password)
        form.build()

        serverError.reset(form.values.updates)

        forward(from: form.submitted, to: signInFx)

        var formSubmitted = 0

        form.submitted.watch { _ in formSubmitted += 1 }
        let signInDone = restore(signInFx.done)
        let signInFail = restore(signInFx.fail)

        email.change("test@example.com")
        password.change("123")

        form.submit()

        XCTAssertEqual(formSubmitted, 1)
        XCTAssert(form.isValid.getState())

        try await Task.sleep(nanoseconds: 1_000_000)

        XCTAssertNotNil(signInFail.getState())

        form.submit()
        form.submit()

        XCTAssertEqual(formSubmitted, 1)

        email.change("pass@example.com")
        form.submit()

        try await Task.sleep(nanoseconds: 1_000_000)

        XCTAssertNotNil(signInDone.getState())

        XCTAssertEqual(formSubmitted, 2)
    }

    func testReset() async throws {
        let form = EffectorForm<SignInForm>()
        let email = form.field(
            keyPath: \.email,
            initialValue: "",
            validator: requiredString
        )
        let password = form.field(
            keyPath: \.password,
            initialValue: "",
            validator: requiredString
        )
        form.register(field: email)
        form.register(field: password)
        form.build()

        email.change("123")
        password.change("123")

        XCTAssertEqual(email.value.getState(), "123")
        XCTAssertEqual(password.value.getState(), "123")

        password.reset()

        XCTAssertEqual(password.value.getState(), "")
        XCTAssertEqual(email.value.getState(), "123")

        password.change("123")
        email.change("")
        form.submit()

        XCTAssertEqual(
            email.firstError.getState(),
            ValidationError(rule: "email", value: "", errorText: "Required")
        )

        XCTAssertNil(password.firstError.getState())

        form.resetForm()

        XCTAssertEqual(email.value.getState(), "")
        XCTAssertEqual(password.value.getState(), "")
        XCTAssertNil(email.firstError.getState())
        XCTAssertNil(password.firstError.getState())
        XCTAssert(form.isValid.getState())
    }

    func testResetErrors() async throws {
        let form = EffectorForm<SignInForm>()
        let email = form.field(keyPath: \.email, initialValue: "", validator: requiredString)
        let password = form.field(
            keyPath: \.password,
            initialValue: "",
            validator: requiredString
        )

        form.register(field: email)
        form.register(field: password)
        form.build()

        form.submit()
        XCTAssertFalse(email.isValid.getState())
        XCTAssertFalse(password.isValid.getState())

        password.resetErrors()

        XCTAssertFalse(email.isValid.getState())
        XCTAssert(password.isValid.getState())

        email.change("123")
        form.submit()

        XCTAssert(email.isValid.getState())
        XCTAssertFalse(password.isValid.getState())

        form.resetErrors()

        XCTAssert(email.isValid.getState())
        XCTAssert(password.isValid.getState())
    }

    // swiftlint:disable:next function_body_length
    func testIsDirtyAndIsTouched() async throws {
        let form = EffectorForm<SignInForm>()
        let email = form.field(keyPath: \.email, initialValue: "", validator: requiredString)
        let password = form.field(
            keyPath: \.password,
            initialValue: "",
            validator: requiredString
        )
        form.register(field: email)
        form.register(field: password)
        form.build()

        XCTAssertFalse(email.isDirty.getState())
        XCTAssertFalse(password.isDirty.getState())
        XCTAssertFalse(form.isDirty.getState())
        XCTAssertFalse(email.isTouched.getState())
        XCTAssertFalse(password.isTouched.getState())
        XCTAssertFalse(form.isTouched.getState())
        XCTAssertEqual(
            form.meta.getState(),
            EffectorForm.Meta(isValid: true, isDirty: false, isTouched: false)
        )

        email.change("123")

        XCTAssert(email.isDirty.getState())
        XCTAssertFalse(password.isDirty.getState())
        XCTAssert(form.isDirty.getState())
        XCTAssert(email.isTouched.getState())
        XCTAssertFalse(password.isTouched.getState())
        XCTAssert(form.isTouched.getState())
        XCTAssertEqual(
            form.meta.getState(),
            EffectorForm.Meta(isValid: true, isDirty: true, isTouched: true)
        )

        password.change("123")

        XCTAssert(email.isDirty.getState())
        XCTAssert(password.isDirty.getState())
        XCTAssert(form.isDirty.getState())
        XCTAssert(email.isTouched.getState())
        XCTAssert(password.isTouched.getState())
        XCTAssert(form.isTouched.getState())
        XCTAssertEqual(
            form.meta.getState(),
            EffectorForm.Meta(isValid: true, isDirty: true, isTouched: true)
        )

        email.change("")

        XCTAssertFalse(email.isDirty.getState())
        XCTAssert(password.isDirty.getState())
        XCTAssert(form.isDirty.getState())
        XCTAssert(email.isTouched.getState())
        XCTAssert(password.isTouched.getState())
        XCTAssert(form.isTouched.getState())
        XCTAssertEqual(
            form.meta.getState(),
            EffectorForm.Meta(isValid: true, isDirty: true, isTouched: true)
        )

        password.change("")

        XCTAssertFalse(email.isDirty.getState())
        XCTAssertFalse(password.isDirty.getState())
        XCTAssertFalse(form.isDirty.getState())
        XCTAssert(email.isTouched.getState())
        XCTAssert(password.isTouched.getState())
        XCTAssert(form.isTouched.getState())
        XCTAssertEqual(
            form.meta.getState(),
            EffectorForm.Meta(isValid: true, isDirty: false, isTouched: true)
        )

        form.resetForm()

        XCTAssertFalse(email.isDirty.getState())
        XCTAssertFalse(password.isDirty.getState())
        XCTAssertFalse(form.isDirty.getState())
        XCTAssertFalse(email.isTouched.getState())
        XCTAssertFalse(password.isTouched.getState())
        XCTAssertFalse(form.isTouched.getState())
        XCTAssertEqual(
            form.meta.getState(),
            EffectorForm.Meta(isValid: true, isDirty: false, isTouched: false)
        )

        email.change("123")
        password.change("123")

        XCTAssert(email.isDirty.getState())
        XCTAssert(password.isDirty.getState())
        XCTAssert(form.isDirty.getState())
        XCTAssert(email.isTouched.getState())
        XCTAssert(password.isTouched.getState())
        XCTAssert(form.isTouched.getState())
        XCTAssertEqual(
            form.meta.getState(),
            EffectorForm.Meta(isValid: true, isDirty: true, isTouched: true)
        )

        form.resetTouched()

        XCTAssert(email.isDirty.getState())
        XCTAssert(password.isDirty.getState())
        XCTAssert(form.isDirty.getState())
        XCTAssertFalse(email.isTouched.getState())
        XCTAssertFalse(password.isTouched.getState())
        XCTAssertFalse(form.isTouched.getState())
        XCTAssertEqual(
            form.meta.getState(),
            EffectorForm.Meta(isValid: true, isDirty: true, isTouched: false)
        )
    }

    func testResetValues() async throws {
        let form = EffectorForm<SignInForm>()

        let email = form.field(
            config: .init(
                keyPath: \.email,
                initialValue: "",
                rules: [.init(name: "required", validator: requiredString)],
                validateOn: Set([.change])
            )
        )

        let password = form.field(
            keyPath: \.password,
            initialValue: "",
            validator: requiredString
        )

        form.register(field: email)
        form.register(field: password)
        form.build()

        email.change("123")
        password.change("123")
        XCTAssertEqual(email.value.getState(), "123")
        XCTAssertNil(email.firstError.getState())
        XCTAssertEqual(password.value.getState(), "123")
        XCTAssertNil(password.firstError.getState())

        form.resetValues()
        XCTAssertEqual(email.value.getState(), "")
        XCTAssertEqual(
            email.firstError.getState(),
            ValidationError(rule: "required", value: "", errorText: "Required")
        )
        XCTAssertEqual(password.value.getState(), "")
        XCTAssertNil(password.firstError.getState())

        email.change("123")
        password.change("123")
        XCTAssertEqual(email.value.getState(), "123")
        XCTAssertNil(email.firstError.getState())
        XCTAssertEqual(password.value.getState(), "123")
        XCTAssertNil(password.firstError.getState())
    }
}

// swiftlint:disable:next type_body_length
final class FieldTests: XCTestCase {
    func createField(
        _ config: EffectorFormFieldConfig<String, SignInForm>
    ) -> EffectorFormField<String, SignInForm> {
        let field = EffectorFormField(config)

        let values = Store(SignInForm(email: "", password: ""))
        let setForm = Event<SignInForm>()
        let resetForm = Event<Void>()
        let resetTouched = Event<Void>()
        let resetValues = Event<Void>()
        let validateForm = Event<Void>()
        let submitForm = Event<Void>()
        let resetFormValues = Event<Void>()
        let resetFormErrors = Event<Void>()

        bindChangeEvent(
            field: field,
            setForm: setForm,
            resetForm: resetForm,
            resetTouched: resetTouched,
            resetValues: resetValues
        )

        bindValidation(
            values: values,
            validateFormEvent: validateForm,
            submitEvent: submitForm,
            resetFormEvent: resetForm,
            resetValues: resetFormValues,
            resetErrorsFormEvent: resetFormErrors,
            field: field,
            formValidationEvents: Set([.submit])
        )

        return field
    }

    func testCreateField() async throws {
        let field = EffectorFormField(
            .init(keyPath: \SignInForm.email, initialValue: "value")
        )

        XCTAssertEqual(field.value.getState(), "value")
        XCTAssertEqual(field.errors.getState(), [])
        XCTAssertNil(field.firstError.getState())

        let addError = Event<ValidationError<String>>()
        field.errors.on(addError) { errors, error in errors + [error] }

        let error = ValidationError(rule: "email", value: "value", errorText: "error")

        let error2 = ValidationError(rule: "minLength", value: "value", errorText: "error2")

        addError(error)
        addError(error2)

        XCTAssertEqual(field.errors.getState(), [error, error2])
        XCTAssertEqual(field.firstError.getState(), error)
    }

    func testBindChangeEvent() async throws {
        let field = EffectorFormField(
            .init(keyPath: \SignInForm.email, initialValue: "")
        )

        let setForm = Event<SignInForm>()
        let resetForm = Event<Void>()
        let resetTouched = Event<Void>()
        let resetValues = Event<Void>()

        bindChangeEvent(
            field: field,
            setForm: setForm,
            resetForm: resetForm,
            resetTouched: resetTouched,
            resetValues: resetValues
        )

        field.change("123")
        XCTAssertEqual(field.value.getState(), "123")

        setForm(.init(email: "1234", password: ""))
        XCTAssertEqual(field.value.getState(), "1234")
    }

    func testBindValidationOnChange() async throws {
        let field = createField(
            .init(
                keyPath: \SignInForm.email,
                initialValue: "",
                rules: [makeEmailValidationRule()],
                validateOn: Set([.change])
            )
        )

        field.change("234")
        XCTAssertEqual(
            field.firstError.getState(),
            ValidationError(rule: "email", value: "234", errorText: "invalid email")
        )

        field.change("234gmail.com")
        XCTAssertEqual(
            field.firstError.getState(),
            ValidationError(rule: "email", value: "234gmail.com", errorText: "invalid email")
        )

        field.change("234@gmail.com")
        XCTAssertNil(field.firstError.getState())
    }

    // swiftlint:disable:next function_body_length
    func testBindValidationOnBlur() async throws {
        let field = EffectorFormField(
            .init(
                keyPath: \SignInForm.email,
                initialValue: "",
                rules: [makeEmailValidationRule()],
                validateOn: Set([.blur])
            )
        )

        let values = Store(SignInForm(email: "", password: ""))
        let setForm = Event<SignInForm>()
        let resetForm = Event<Void>()
        let resetTouched = Event<Void>()
        let resetValues = Event<Void>()
        let validateForm = Event<Void>()
        let submitForm = Event<Void>()
        let resetFormValues = Event<Void>()
        let resetFormErrors = Event<Void>()

        bindChangeEvent(
            field: field,
            setForm: setForm,
            resetForm: resetForm,
            resetTouched: resetTouched,
            resetValues: resetValues
        )

        bindValidation(
            values: values,
            validateFormEvent: validateForm,
            submitEvent: submitForm,
            resetFormEvent: resetForm,
            resetValues: resetFormValues,
            resetErrorsFormEvent: resetFormErrors,
            field: field,
            formValidationEvents: Set([.submit])
        )

        field.change("1245")
        XCTAssertNil(field.firstError.getState())

        field.blur()
        XCTAssertEqual(
            field.firstError.getState(),
            ValidationError(rule: "email", value: "1245", errorText: "invalid email")
        )
        field.change("1245-")
        XCTAssertNil(field.firstError.getState())

        submitForm()
        XCTAssertEqual(
            field.firstError.getState(),
            ValidationError(rule: "email", value: "1245-", errorText: "invalid email")
        )

        field.change("1245@gmail.com")
        XCTAssertNil(field.firstError.getState())
        submitForm()
        XCTAssertNil(field.firstError.getState())
    }

    func testFilter() async throws {
        let setFilter = Event<Bool>()
        let filter = restore(setFilter, false)

        let field = createField(
            .init(
                keyPath: \SignInForm.email,
                initialValue: "",
                rules: [makeEmailValidationRule()],
                filter: filter
            )
        )

        field.change("123")
        XCTAssertEqual(field.value.getState(), "")

        setFilter(true)
        field.change("123")
        XCTAssertEqual(field.value.getState(), "123")
    }

    func testAddErrorManually() async throws {
        let field = createField(
            .init(
                keyPath: \SignInForm.email,
                initialValue: "",
                validateOn: Set([.change])
            )
        )

        field.change("123")

        field.addError(FormFieldError(rule: "custom-rule", errorText: "error-text"))

        XCTAssertEqual(
            field.firstError.getState(),
            ValidationError(
                rule: "custom-rule",
                value: "123",
                errorText: "error-text"
            )
        )

        field.change("123")

        XCTAssertNil(field.firstError.getState())
    }

    func testValidateManually() async throws {
        let field = createField(
            .init(
                keyPath: \SignInForm.email,
                initialValue: "",
                rules: [makeEmailValidationRule()]
            )
        )

        field.change("123")

        XCTAssertEqual(field.value.getState(), "123")
        XCTAssertNil(field.firstError.getState())

        field.validate()
        XCTAssertEqual(
            field.firstError.getState(),
            ValidationError(rule: "email", value: "123", errorText: "invalid email")
        )

        field.change("1234")

        XCTAssertNil(field.firstError.getState())
    }

    func testResetErrors() async throws {
        let field = createField(
            .init(
                keyPath: \SignInForm.email,
                initialValue: "",
                rules: [makeEmailValidationRule()]
            )
        )

        field.change("123")
        field.validate()

        XCTAssertEqual(
            field.firstError.getState(),
            ValidationError(rule: "email", value: "123", errorText: "invalid email")
        )

        field.resetErrors()

        XCTAssertNil(field.firstError.getState())
    }

    func testResetValue() async throws {
        let field = createField(
            .init(
                keyPath: \SignInForm.email,
                initialValue: "",
                rules: [makeEmailValidationRule()],
                validateOn: Set([.change])
            )
        )

        field.change("test@example.com")
        XCTAssertEqual(field.value.getState(), "test@example.com")
        XCTAssertNil(field.firstError.getState())

        field.resetValue()
        XCTAssertEqual(field.value.getState(), "")
        XCTAssertEqual(
            field.firstError.getState(),
            ValidationError(rule: "email", value: "", errorText: "invalid email")
        )
    }

    func testIsDirtyIsTouched() async throws {
        let field = createField(
            .init(
                keyPath: \SignInForm.email,
                initialValue: "",
                rules: [makeEmailValidationRule()]
            )
        )

        XCTAssertFalse(field.isDirty.getState())
        XCTAssertFalse(field.isTouched.getState())

        field.change("123")
        XCTAssert(field.isDirty.getState())
        XCTAssert(field.isTouched.getState())

        field.change("")
        XCTAssertFalse(field.isDirty.getState())
        XCTAssert(field.isTouched.getState())

        field.reset()
        XCTAssertFalse(field.isDirty.getState())
        XCTAssertFalse(field.isTouched.getState())

        field.change("123")
        XCTAssert(field.isDirty.getState())
        XCTAssert(field.isTouched.getState())

        field.resetTouched()
        XCTAssert(field.isDirty.getState())
        XCTAssertFalse(field.isTouched.getState())
    }
}
