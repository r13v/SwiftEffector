extension Store {
    @discardableResult
    func debug() -> Self {
        self.watch {
            print("\(self.graphite) -> ", $0)
        }

        return self
    }
}

extension Event {
    @discardableResult
    func debug() -> Self {
        self.watch {
            print("\(self.graphite) -> ", $0)
        }

        return self
    }
}

extension Effect {
    @discardableResult
    func debug() -> Self {
        self.watch {
            print("\(self.graphite) -> ", $0)
        }

        self.pending.watch {
            print("\(self.graphite) -> ", $0)
        }

        self.done.watch {
            print("\(self.graphite) -> ", $0)
        }

        self.fail.watch {
            print("\(self.graphite) -> ", $0)
        }

        return self
    }
}
