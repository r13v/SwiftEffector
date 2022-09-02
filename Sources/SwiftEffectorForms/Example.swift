import Foundation
import SwiftEffector
import SwiftUI

// MARK: - Example

struct Email {
    enum EmailParseError: Error, LocalizedError {
        case noAtSymbol

        // MARK: Internal

        var errorDescription: String? {
            switch self {
            case .noAtSymbol: return "Email should contain '@' symbol."
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

struct SignInForm: Codable {
    var email: String
    var password: String
}
