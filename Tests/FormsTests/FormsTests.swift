
import SwiftEffector
@testable import SwiftEffectorForms
import XCTest

final class FormsTests: XCTestCase {
    func testForm() async throws {
        struct SignInFormValues: Combinable {
            subscript(key: String) -> Any? {
                get {
                    switch key {
                    case "email": return email
                    case "password": return password
                    default: return nil
                    }
                }
                set(newValue) {
                    switch key {
                    case "email": email = newValue as! String
                    case "password": password = newValue as! String
                    default: return
                    }
                }
            }

            var email: String
            var password: String
        }

//        let formConfig = EForm<SignInFormValues>.Config(
//            fields: [
//                .init(
//                    name: \.email,
//                    initialValue: "",
//                    rules: [
//                        .init(name: "email", validator: { value, _ in value.contains("@") })
//                    ]
//                )
//            ]
//        )
    }
}
