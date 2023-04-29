func uniqId(_ prefix: String = "") -> () -> String {
    var n = 0

    return {
        n += 1
        return "\(prefix)\(n)"
    }
}
