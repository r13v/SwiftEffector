@testable import EffectorForms
import XCTest

final class ValidatorsTests: XCTestCase {
    struct TestForm: FormValues {
        static var `default` = TestForm(abc: "", n: 0)

        var abc: String
        var n: Int
    }

    func testStringRequired() async throws {
        let validator = ValidationRule<String, TestForm>.required().validator

        let testCases = [
            (msg: "empty", input: "", want: false),
            (msg: "non-empty", input: "abc", want: true),
            (msg: "whitespaces", input: "  ", want: false),
        ]

        for tc in testCases {
            let got = validator(tc.input, TestForm.default) == nil

            XCTAssertEqual(got, tc.want, tc.msg)
        }
    }

    func testStringLength() async throws {
        let validator = ValidationRule<String, TestForm>.length(3).validator

        let testCases = [
            (msg: "match", input: "abc", want: true),
            (msg: "not match", input: "a", want: false),
        ]

        for tc in testCases {
            let got = validator(tc.input, TestForm.default) == nil

            XCTAssertEqual(got, tc.want, tc.msg)
        }
    }

    func testStringMin() async throws {
        let validator = ValidationRule<String, TestForm>.min(3).validator

        let testCases = [
            (msg: "more", input: "abcd", want: true),
            (msg: "equal", input: "abc", want: true),
            (msg: "less", input: "ab", want: false),
        ]

        for tc in testCases {
            let got = validator(tc.input, TestForm.default) == nil

            XCTAssertEqual(got, tc.want, tc.msg)
        }
    }

    func testStringMax() async throws {
        let validator = ValidationRule<String, TestForm>.max(3).validator

        let testCases = [
            (msg: "more", input: "abcd", want: false),
            (msg: "equal", input: "abc", want: true),
            (msg: "less", input: "ab", want: true),
        ]

        for tc in testCases {
            let got = validator(tc.input, TestForm.default) == nil

            XCTAssertEqual(got, tc.want, tc.msg)
        }
    }

    func testStringURL() async throws {
        let validator = ValidationRule<String, TestForm>.url().validator

        let testCases = [
            (msg: "valid", input: "https://google.com", want: true),
            (msg: "invalid", input: "abc", want: false),
        ]

        for tc in testCases {
            let got = validator(tc.input, TestForm.default) == nil

            XCTAssertEqual(got, tc.want, tc.msg)
        }
    }

    func testStringEmail() async throws {
        let validator = ValidationRule<String, TestForm>.email().validator

        let testCases = [
            (msg: "valid", input: "user@example.com", want: true),
            (msg: "invalid", input: "abc", want: false),
        ]

        for tc in testCases {
            let got = validator(tc.input, TestForm.default) == nil

            XCTAssertEqual(got, tc.want, tc.msg)
        }
    }

    func testStringMatches() async throws {
        let regex = try NSRegularExpression(pattern: #"\d+$"#)
        let validator = ValidationRule<String, TestForm>.matches(regex).validator

        let testCases = [
            (msg: "valid", input: "123", want: true),
            (msg: "invalid", input: "abc", want: false),
        ]

        for tc in testCases {
            let got = validator(tc.input, TestForm.default) == nil

            XCTAssertEqual(got, tc.want, tc.msg)
        }
    }

    func testStringTrim() async throws {
        let validator = ValidationRule<String, TestForm>.trim().validator

        let testCases = [
            (msg: "valid", input: "abc", want: true),
            (msg: "invalid", input: "abc ", want: false),
        ]

        for tc in testCases {
            let got = validator(tc.input, TestForm.default) == nil

            XCTAssertEqual(got, tc.want, tc.msg)
        }
    }

    func testIntMin() async throws {
        let validator = ValidationRule<Int, TestForm>.min(10).validator

        let testCases = [
            (msg: "equal", input: 10, want: true),
            (msg: "more", input: 100, want: true),
            (msg: "less", input: 2, want: false),
        ]

        for tc in testCases {
            let got = validator(tc.input, TestForm.default) == nil

            XCTAssertEqual(got, tc.want, tc.msg)
        }
    }

    func testIntMax() async throws {
        let validator = ValidationRule<Int, TestForm>.max(10).validator

        let testCases = [
            (msg: "equal", input: 10, want: true),
            (msg: "more", input: 100, want: false),
            (msg: "less", input: 2, want: true),
        ]

        for tc in testCases {
            let got = validator(tc.input, TestForm.default) == nil

            XCTAssertEqual(got, tc.want, tc.msg)
        }
    }

    func testIntMoreThan() async throws {
        let validator = ValidationRule<Int, TestForm>.moreThan(10).validator

        let testCases = [
            (msg: "equal", input: 10, want: false),
            (msg: "more", input: 100, want: true),
            (msg: "less", input: 2, want: false),
        ]

        for tc in testCases {
            let got = validator(tc.input, TestForm.default) == nil

            XCTAssertEqual(got, tc.want, tc.msg)
        }
    }

    func testIntLessThan() async throws {
        let validator = ValidationRule<Int, TestForm>.lessThan(10).validator

        let testCases = [
            (msg: "equal", input: 10, want: false),
            (msg: "more", input: 100, want: false),
            (msg: "less", input: 2, want: true),
        ]

        for tc in testCases {
            let got = validator(tc.input, TestForm.default) == nil

            XCTAssertEqual(got, tc.want, tc.msg)
        }
    }
}
