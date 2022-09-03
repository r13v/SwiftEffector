final class NextID {
    // MARK: Internal

    func callAsFunction() -> Int {
        n += 1

        return n
    }

    // MARK: Private

    private var n = 0
}
