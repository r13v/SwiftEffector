# SwiftEffector

[Effector](https://effector.dev/) port.

```swift
import Effector
import SwiftUI

enum CounterFeature {
    static let counter = Store(0)
    static let inc = Event<Void>()
    static let dec = Event<Void>()
    static let CounterGate = Gate<Int>()

    static let logFx = Effect<Int, Void, Error> { n in print("n: \(n)") }

    static let incAsync: Effect<Void, Int, Error> = attach(store: counter) { store, _ in
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        return store + 10
    }

    static func bind() {
        counter
            .on(inc) { n, _ in n + 1 }
            .on(dec) { n, _ in n - 1 }
            .on(incAsync.doneData) { _, n in n }

        sample(
            trigger: counter.updates,
            target: logFx
        )

        CounterGate.open.watch { print("Gate open: \($0)") }
        CounterGate.close.watch { print("Gate close: \($0)") }
        CounterGate.status.watch { print("Gate status: \($0)") }
        CounterGate.state.watch { print("Gate state: \(String(describing: $0))") }
    }
}

struct ContentView: View {
    // MARK: Lifecycle

    init() {
        CounterFeature.bind()
    }

    // MARK: Internal

    @Use(CounterFeature.counter)
    var counter

    var body: some View {
        VStack {
            Text("\(counter)")

            Button("dec", action: CounterFeature.dec.run)
            Button("inc", action: CounterFeature.inc.run)
            Button("inc 10 async", action: { Task { await CounterFeature.incAsync() }})
            Button("set 100") { counter = 100 }
            CounterFeature.CounterGate(counter)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

```
