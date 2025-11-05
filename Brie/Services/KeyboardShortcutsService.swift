import Foundation
import AppKit
import Combine

@MainActor
class KeyboardShortcutsService: ObservableObject {
    static let shared = KeyboardShortcutsService()
    
    @Published var shortcuts: [String: KeyboardShortcut] = [:]
    nonisolated(unsafe) private var eventMonitor: Any?
    
    struct KeyboardShortcut: Codable {
        let action: String
        let key: String
        let modifiers: [String]
        
        var displayString: String {
            let modifierSymbols = modifiers.map { modifier -> String in
                switch modifier {
                case "command": return "⌘"
                case "option": return "⌥"
                case "shift": return "⇧"
                case "control": return "⌃"
                default: return ""
                }
            }.joined()
            
            return modifierSymbols + key.uppercased()
        }
    }
    
    init() {
        loadDefaultShortcuts()
        setupEventMonitor()
    }
    
    private func loadDefaultShortcuts() {
        shortcuts = [
            "newTrail": KeyboardShortcut(action: "newTrail", key: "n", modifiers: ["command"]),
            "newSubTrail": KeyboardShortcut(action: "newSubTrail", key: "t", modifiers: ["command", "option"]),
            "newSideTrail": KeyboardShortcut(action: "newSideTrail", key: "t", modifiers: ["command", "option", "shift"]),
            "closeTrail": KeyboardShortcut(action: "closeTrail", key: "w", modifiers: ["command"]),
            "renameTrail": KeyboardShortcut(action: "renameTrail", key: "l", modifiers: ["command", "shift"]),
            "toggleSidebar": KeyboardShortcut(action: "toggleSidebar", key: "s", modifiers: ["command", "option"]),
            "settings": KeyboardShortcut(action: "settings", key: ",", modifiers: ["command"]),
            "collapseTrail": KeyboardShortcut(action: "collapseTrail", key: "ArrowLeft", modifiers: ["command", "shift"]),
            "expandTrail": KeyboardShortcut(action: "expandTrail", key: "ArrowRight", modifiers: ["command", "shift"])
        ]
    }
    
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            return self.handleKeyEvent(event) ? nil : event
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let keyChar = event.charactersIgnoringModifiers ?? ""
        let modifiers = event.modifierFlags
        let keyCode = event.keyCode
        
        for (_, shortcut) in shortcuts {
            var matches = false
            
            if shortcut.key.starts(with: "Arrow") {
                let expectedKeyCode: UInt16
                switch shortcut.key {
                case "ArrowLeft": expectedKeyCode = 123
                case "ArrowRight": expectedKeyCode = 124
                case "ArrowDown": expectedKeyCode = 125
                case "ArrowUp": expectedKeyCode = 126
                default: continue
                }
                matches = keyCode == expectedKeyCode
            } else {
                matches = keyChar.lowercased() == shortcut.key.lowercased()
            }
            
            if matches {
                if shortcut.modifiers.contains("command") && !modifiers.contains(.command) {
                    matches = false
                }
                if shortcut.modifiers.contains("option") && !modifiers.contains(.option) {
                    matches = false
                }
                if shortcut.modifiers.contains("shift") && !modifiers.contains(.shift) {
                    matches = false
                }
                if shortcut.modifiers.contains("control") && !modifiers.contains(.control) {
                    matches = false
                }
            }
            
            if matches {
                executeAction(shortcut.action)
                return true
            }
        }
        
        return false
    }
    
    private func executeAction(_ action: String) {
        switch action {
        case "newTrail":
            NotificationCenter.default.post(name: .createNewTrail, object: nil)
        case "newSubTrail":
            NotificationCenter.default.post(name: .createNewSubTrail, object: nil)
        case "newSideTrail":
            NotificationCenter.default.post(name: .createNewSideTrail, object: nil)
        case "toggleSidebar":
            NotificationCenter.default.post(name: .toggleSidebar, object: nil)
        case "collapseTrail":
            NotificationCenter.default.post(name: .collapseTrail, object: nil)
        case "expandTrail":
            NotificationCenter.default.post(name: .expandTrail, object: nil)
        default:
            break
        }
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

