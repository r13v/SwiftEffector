public extension Store {
    @discardableResult
    func debug() -> Self {
        self.watch {
            debugPrint("\(self.graphite) -> \(String(describing: $0))")
        }

        return self
    }
}

public extension Event {
    @discardableResult
    func debug() -> Self {
        self.watch {
            debugPrint("\(self.graphite) -> \(String(describing: $0))")
        }

        return self
    }
}

public extension Effect {
    @discardableResult
    func debug() -> Self {
        self.watch {
            debugPrint("\(self.graphite) -> \(String(describing: $0))")
        }

        self.pending.watch {
            debugPrint("\(self.graphite) -> \(String(describing: $0))")
        }

        self.done.watch {
            debugPrint("\(self.graphite) -> \(String(describing: $0))")
        }

        self.fail.watch {
            debugPrint("\(self.graphite) -> \(String(describing: $0))")
        }

        return self
    }
}
