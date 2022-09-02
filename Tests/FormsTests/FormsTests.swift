
import SwiftEffector
@testable import SwiftEffectorForms
import XCTest

struct Email {
    enum EmailParseError: Error, LocalizedError {
        case noAtSymbol

        // MARK: Internal

        var errorDescription: String? {
            switch self {
            case .noAtSymbol: return "Email should contain '@' symbol"
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

struct SignInForm: Codable, Equatable {
    var email: String
    var password: String
}

func minLength<Values>(_ min: Int) -> (_ value: String, _: Values) -> String? {
    { value, _ in value.count >= min ? nil : "Minimum \(min) symbols" }
}

func validEmail<Values>(_ value: String, _: Values) -> String? {
    Email.parse(value).errorString
}

func required<Values>(_ value: String, _: Values) -> String? {
    value.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 ? nil : "Required"
}
final class FormsTests: XCTestCase {
    func testSignInForm() async throws {
        let form = EffectorForm<SignInForm>()
        let email = form.register("email", \.email, "", validEmail)
        let password = form.register("password", \.password, "", [.init(name: "minLength", validator: minLength(4))])

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
        XCTAssertEqual(email.firstError.getState()!, ValidationError(rule: "email", value: "invalid", errorText: "Email should contain '@' symbol"))
        XCTAssertEqual(password.firstError.getState()!, ValidationError(rule: "minLength", value: "", errorText: "Minimum 4 symbols"))

        email.change("test")

        XCTAssertNil(email.firstError.getState())
        XCTAssertFalse(form.isValid.getState())

        form.submit()

        XCTAssertFalse(form.isValid.getState())
        XCTAssertEqual(email.firstError.getState()!, ValidationError(rule: "email", value: "test", errorText: "Email should contain '@' symbol"))

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
}
