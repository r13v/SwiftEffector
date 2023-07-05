# SwiftEffector

 [Effector](https://effector.dev/) port.

```swift
import Effector
import SwiftUI

enum CounterFeature {
    static let counter = Store(0)
    static let inc = Event<Void>()
    static let dec = Event<Void>()

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
            Button("inc 10 async", action: { Task { try await CounterFeature.incAsync() }})
            Button("set 100") { counter = 100 }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

```
