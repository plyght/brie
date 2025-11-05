import SwiftUI

@main
struct BrieApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var coreDataStack = CoreDataStack.shared
    
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .frame(minWidth: 800, minHeight: 600)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Trail") {
                    NotificationCenter.default.post(name: .createNewTrail, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)
                
                Button("New SubTrail") {
                    NotificationCenter.default.post(name: .createNewSubTrail, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .option])
                
                Button("New SideTrail") {
                    NotificationCenter.default.post(name: .createNewSideTrail, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .option, .shift])
            }
            
            CommandGroup(after: .sidebar) {
                Button("Toggle Sidebar") {
                    NotificationCenter.default.post(name: .toggleSidebar, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}

extension Notification.Name {
    static let createNewTrail = Notification.Name("createNewTrail")
    static let createNewSubTrail = Notification.Name("createNewSubTrail")
    static let createNewSideTrail = Notification.Name("createNewSideTrail")
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let collapseTrail = Notification.Name("collapseTrail")
    static let expandTrail = Notification.Name("expandTrail")
    static let coreDataSaveError = Notification.Name("coreDataSaveError")
}

