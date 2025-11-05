import Foundation
import SwiftUI

extension String {
    var isValidURL: Bool {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return false
        }
        let range = NSRange(location: 0, length: utf16.count)
        let matches = detector.matches(in: self, options: [], range: range)
        return matches.first?.url != nil
    }
    
    func toURL() -> URL? {
        if hasPrefix("http://") || hasPrefix("https://") {
            return URL(string: self)
        }
        if self.contains(".") && !self.contains(" ") {
            return URL(string: "https://\(self)")
        }
        return nil
    }
}

extension View {
    func hideKeyboardShortcutLabel() -> some View {
        self.keyboardShortcut(KeyEquivalent("\0"), modifiers: [])
    }
}

