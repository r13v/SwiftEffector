func uniqId() -> () -> Int {
    var n = 0

    return {
        n += 1
        return n
    }
}
