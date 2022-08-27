# SwiftEffector

 [Effector](https://effector.dev/) port.

```swift
import SwiftEffector
import SwiftUI

let store = Store(0)
let inc = Event<Void>()
let dec = Event<Void>()

let logFx = Effect<Int, Void, Error> { n in print("n: \(n)") }

let incAsync: Effect<Void, Int, Error> = attach(store: store) { store, _ in
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    return store + 10
}

func bootstrap() {
    store
        .on(inc) { n, _ in n + 1 }
        .on(dec) { n, _ in n - 1 }

    sample(
        trigger: store.updates,
        source: store,
        map: { s, _ in s + 10 },
        target: logFx
    )

    forward(from: [incAsync.doneData], to: [store])
}

struct ContentView: View {
    init() {
        bootstrap()
    }

    @UseStore(store) var value

    var body: some View {
        VStack {
            Text("\(value)")

            Button("dec", action: dec.run)
            Button("inc", action: inc.run)
            Button("inc 10 async", action: { Task { try await incAsync.run() }})
            Button("set 100") { value = 100 }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
```
