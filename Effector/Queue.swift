import Foundation

class Queue {
    // MARK: Public

    public var count: Int {
        list.count
    }

    // MARK: Internal

    struct Element: CustomStringConvertible {
        var node: Node
        var value: Any

        var description: String {
            "\(node) | \(value)"
        }
    }

    static let shared = Queue()

    func enqueue<Payload>(_ node: Node, _ value: Payload) {
        lock.lock()
        defer { lock.unlock() }
        list.append(Element(node: node, value: value as Any))
        up(count - 1)
    }

    func dequeue() -> Element? {
        lock.lock()
        defer { lock.unlock() }
        guard !list.isEmpty else {
            return nil
        }

        if list.count == 1 {
            return list.removeFirst()
        }

        let element = list[0]
        list[0] = list.removeLast()
        down(0)

        return element
    }

    // MARK: Private

    private let lock = NSLock()

    private var list: [Element] = []

    private func left(_ index: Int) -> Int {
        2 * index + 1
    }

    private func right(_ index: Int) -> Int {
        2 * index + 2
    }

    private func parent(_ index: Int) -> Int {
        (index - 1) / 2
    }

    private func down(_ index: Int) {
        let left = left(index)
        let right = right(index)

        var first = index

        if left < count, sort(list[left], list[first]) {
            first = left
        }

        if right < count, sort(list[right], list[first]) {
            first = right
        }

        if first == index {
            return
        }

        list.swapAt(index, first)
        down(first)
    }

    private func up(_ index: Int) {
        var childIndex = index
        let child = list[childIndex]
        var parentIndex = parent(childIndex)

        while childIndex > 0, sort(child, list[parentIndex]) {
            list[childIndex] = list[parentIndex]
            childIndex = parentIndex
            parentIndex = parent(childIndex)
        }

        list[childIndex] = child
    }

    private func sort(_ lhs: Element, _ rhs: Element) -> Bool {
        if lhs.node.priority == rhs.node.priority {
            return lhs.node.id < rhs.node.id
        }

        return lhs.node.priority.rawValue < rhs.node.priority.rawValue
    }
}

extension Queue: CustomStringConvertible {
    var description: String {
        list.map(\.description).joined(separator: "\n")
    }
}
