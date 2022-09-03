public protocol Unit {
    var name: String { get }
    var kind: String { get }
    var graphite: Node { get set }
}
