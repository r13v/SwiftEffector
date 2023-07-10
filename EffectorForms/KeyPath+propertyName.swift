import Foundation

extension KeyPath {
    var propertyName: String {
        let keyPathString = String(describing: self)
        let keyPathStringLastPart = keyPathString.split(separator: ".").last!
        return String(keyPathStringLastPart)
    }
}
