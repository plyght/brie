import SwiftUI
import AppKit

extension View {
    func onKeyPress(_ key: KeyEquivalent, modifiers: EventModifiers = [], perform action: @escaping () -> Void) -> some View {
        self.background(KeyPressHandler(key: key, modifiers: modifiers, action: action))
    }
}

struct KeyPressHandler: NSViewRepresentable {
    let key: KeyEquivalent
    let modifiers: EventModifiers
    let action: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyEventView()
        view.keyHandler = { event in
            let keyChar = event.charactersIgnoringModifiers ?? ""
            let eventModifiers = event.modifierFlags
            
            var matches = true
            
            if modifiers.contains(.command) && !eventModifiers.contains(.command) {
                matches = false
            }
            if modifiers.contains(.option) && !eventModifiers.contains(.option) {
                matches = false
            }
            if modifiers.contains(.shift) && !eventModifiers.contains(.shift) {
                matches = false
            }
            if modifiers.contains(.control) && !eventModifiers.contains(.control) {
                matches = false
            }
            
            if matches && keyChar == String(key.character) {
                action()
                return true
            }
            
            return false
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class KeyEventView: NSView {
    var keyHandler: ((NSEvent) -> Bool)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        if keyHandler?(event) != true {
            super.keyDown(with: event)
        }
    }
}

