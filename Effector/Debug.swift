extension Store {
    @discardableResult
    func debug() -> Self {
        print("\(self.name)::init -> ", self.currentState)

        self.watch { state in
            print("\(self.name) -> ", state)
        }

        return self
    }
}

extension Event {
    @discardableResult
    func debug() -> Self {
        self.watch { payload in
            print("\(self.name) -> ", payload)
        }

        return self
    }
}

extension Effect {
    @discardableResult
    func debug() -> Self {
        self.watch { payload in
            print("\(self.name) -> ", payload)
        }

        self.pending.watch { pending in
            print("\(self.name)::pending -> ", pending)
        }

        self.done.watch { done in
            print("\(self.name)::done -> ", done)
        }

        self.fail.watch { fail in
            print("\(self.name)::fail -> ", fail)
        }

        return self
    }
}
