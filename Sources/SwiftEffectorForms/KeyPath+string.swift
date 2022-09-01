import Foundation

public extension KeyPath {
    var asString: String {
        NSExpression(forKeyPath: self).keyPath
    }
}
