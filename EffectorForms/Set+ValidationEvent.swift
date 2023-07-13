extension Set where Element == ValidationEvent {
    static let all = Set(ValidationEvent.allCases)

    static let submit = Set([ValidationEvent.submit])
    static let change = Set([ValidationEvent.change])
    static let blur = Set([ValidationEvent.blur])
}
