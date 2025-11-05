import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var keyboardShortcutsService: KeyboardShortcutsService?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        keyboardShortcutsService = KeyboardShortcutsService.shared
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        CoreDataStack.shared.saveContext()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

