public extension Store where State == Bool {
    func not() -> Store<Bool> {
        self.map { !$0 }
    }
}
