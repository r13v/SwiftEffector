public extension Result {
    var errorString: String? {
        switch self {
        case .success: return nil
        case .failure(let error): return error.localizedDescription
        }
    }
}
