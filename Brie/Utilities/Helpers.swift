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

extension URL {
    func abbreviated() -> String {
        guard let host = self.host else {
            return self.absoluteString
        }
        
        let path = self.path
        
        if path.isEmpty || path == "/" {
            return host
        }
        
        let pathComponents = path.split(separator: "/").map(String.init)
        
        if pathComponents.count <= 1 {
            return host + path
        }
        
        if pathComponents.count == 2 {
            return host + path
        }
        
        if let lastComponent = pathComponents.last {
            return "\(host)/…/\(lastComponent)"
        }
        
        return host + path
    }
}

extension View {
    func hideKeyboardShortcutLabel() -> some View {
        self.keyboardShortcut(KeyEquivalent("\0"), modifiers: [])
    }
}

