import SwiftUI
import WebKit

struct SettingsView: View {
    @StateObject private var searchEngineService = SearchEngineService.shared
    @State private var selectedTab: SettingsTab = .general
    @AppStorage("showSidebarOnLaunch") private var showSidebarOnLaunch = true
    @AppStorage("restorePreviousSession") private var restorePreviousSession = true
    
    enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case appearance = "Appearance"
        case extensions = "Extensions"
        case shortcuts = "Shortcuts"
        case advanced = "Advanced"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .appearance: return "paintbrush"
            case .extensions: return "puzzlepiece.extension"
            case .shortcuts: return "keyboard"
            case .advanced: return "slider.horizontal.3"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView(sidebar: {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 180)
        }, detail: {
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsView(searchEngineService: searchEngineService, 
                                       showSidebarOnLaunch: $showSidebarOnLaunch,
                                       restorePreviousSession: $restorePreviousSession)
                case .appearance:
                    AppearanceSettingsView()
                case .extensions:
                    ExtensionsSettingsView()
                case .shortcuts:
                    KeyboardShortcutsSettingsView()
                case .advanced:
                    AdvancedSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        })
        .frame(width: 750, height: 550)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var searchEngineService: SearchEngineService
    @Binding var showSidebarOnLaunch: Bool
    @Binding var restorePreviousSession: Bool
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("General")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Configure general browser settings and behavior")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Search Engine")
                                .font(.headline)
                            
                            Picker("Default search engine", selection: $searchEngineService.currentSearchEngine) {
                                ForEach(searchEngineService.availableSearchEngines) { engine in
                                    Text(engine.name).tag(engine)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            
                            Text("Choose your preferred search engine for address bar queries")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("On Launch")
                            .font(.headline)
                        
                        Toggle("Show sidebar on launch", isOn: $showSidebarOnLaunch)
                        
                        Toggle("Restore previous session", isOn: $restorePreviousSession)
                        
                        Text("Automatically restore your trails and pages from your last session")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Spacer()
            }
            .padding(24)
        }
        .formStyle(.grouped)
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("abbreviateURLs") private var abbreviateURLs = true
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Appearance")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Customize the look and feel of Brie")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Interface")
                            .font(.headline)
                        
                        Toggle("Abbreviate URLs in address bar", isOn: $abbreviateURLs)
                        
                        Text("When enabled, long URLs will be shortened to show only the domain and last path segment")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Text("The Brie browser uses your system appearance settings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("To change the appearance, go to System Settings > Appearance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Spacer()
            }
            .padding(24)
        }
        .formStyle(.grouped)
    }
}

struct KeyboardShortcutsSettingsView: View {
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Keyboard Shortcuts")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("View and manage keyboard shortcuts for common actions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trail Management")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        ShortcutRow(action: "New Trail", shortcut: KeyboardShortcuts.newTrail)
                        ShortcutRow(action: "New SubTrail", shortcut: KeyboardShortcuts.newSubTrail)
                        ShortcutRow(action: "New SideTrail", shortcut: KeyboardShortcuts.newSideTrail)
                        ShortcutRow(action: "Close Trail/Page", shortcut: KeyboardShortcuts.closeTrail)
                        ShortcutRow(action: "Rename Trail", shortcut: KeyboardShortcuts.renameTrail)
                    }
                    .padding(.vertical, 8)
                }
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Navigation")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        ShortcutRow(action: "Toggle Sidebar", shortcut: KeyboardShortcuts.toggleSidebar)
                        ShortcutRow(action: "Focus Address Bar", shortcut: "⌘L")
                        ShortcutRow(action: "Collapse Trail", shortcut: KeyboardShortcuts.collapseTrail)
                        ShortcutRow(action: "Expand Trail", shortcut: KeyboardShortcuts.expandTrail)
                    }
                    .padding(.vertical, 8)
                }
                
                Spacer()
            }
            .padding(24)
        }
        .formStyle(.grouped)
    }
}

struct ShortcutRow: View {
    let action: String
    let shortcut: String
    
    var body: some View {
        HStack {
            Text(action)
                .font(.subheadline)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
        }
    }
}

struct ExtensionsSettingsView: View {
    @StateObject private var authService = AuthenticationService.shared
    @AppStorage("extensionsEnabled") private var extensionsEnabled = true
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Extensions")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Manage Safari App Extensions and security settings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Extension Support")
                            .font(.headline)
                        
                        Toggle("Enable Safari Extensions", isOn: $extensionsEnabled)
                        
                        Text("Allow Safari App Extensions to interact with web content")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Button(action: {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.extensions") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Label("Open Safari Extensions Settings", systemImage: "gearshape.2")
                        }
                        .buttonStyle(.bordered)
                        
                        Text("Configure and enable Brie Extension in Safari settings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Authentication")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Biometric Authentication")
                                    .font(.subheadline)
                                Text(authService.hasBiometrics ? "\(authService.biometricTypeString) available" : "Not available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: authService.hasBiometrics ? "touchid" : "lock.slash")
                                .font(.title2)
                                .foregroundColor(authService.hasBiometrics ? .green : .secondary)
                        }
                        
                        Text("Websites can request biometric authentication for passkeys and WebAuthn")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Installed Extensions")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Brie Extension")
                                    .font(.subheadline)
                                Text("Core browser extension")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("Built-in")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Spacer()
            }
            .padding(24)
        }
        .formStyle(.grouped)
    }
}

struct AdvancedSettingsView: View {
    @State private var showingClearDataAlert = false
    @State private var showingClearCacheAlert = false
    @State private var alertMessage: String?
    @State private var showingResultAlert = false
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Advanced")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Manage data, storage, and advanced settings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Data Management")
                            .font(.headline)
                        
                        Button(action: {
                            let markdown = TrailManager.shared.exportTrailsToMarkdown()
                            let panel = NSSavePanel()
                            panel.allowedContentTypes = [.plainText]
                            panel.nameFieldStringValue = "trails.md"
                            panel.begin { response in
                                if response == .OK, let url = panel.url {
                                    try? markdown.write(to: url, atomically: true, encoding: .utf8)
                                }
                            }
                        }) {
                            Label("Export Trails to Markdown", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                        
                        Text("Export all your trails and pages to a markdown file")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            showingClearDataAlert = true
                        }) {
                            Label("Clear All Data", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        
                        Text("Warning: This will permanently delete all trails, pages, and notes")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .padding(.vertical, 8)
                }
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Storage")
                            .font(.headline)
                        
                        Button(action: {
                            showingClearCacheAlert = true
                        }) {
                            Label("Clear Cache", systemImage: "trash.circle")
                        }
                        .buttonStyle(.bordered)
                        
                        Text("Clear website data and cache. You may need to log in to websites again")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Spacer()
            }
            .padding(24)
        }
        .formStyle(.grouped)
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All Data", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all Trails, Pages, Areas, Folders, and Notes. This action cannot be undone.")
        }
        .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear Cache", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("This will clear all website data and cache. You may need to log in to websites again.")
        }
        .alert("Result", isPresented: $showingResultAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let message = alertMessage {
                Text(message)
            }
        }
    }
    
    private func clearAllData() {
        do {
            try PersistenceService.shared.clearAllData()
            TrailManager.shared.fetchAllData()
            alertMessage = "All data has been cleared successfully."
            showingResultAlert = true
        } catch {
            alertMessage = "Failed to clear data: \(error.localizedDescription)"
            showingResultAlert = true
        }
    }
    
    private func clearCache() {
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let date = Date(timeIntervalSince1970: 0)
        
        dataStore.removeData(ofTypes: dataTypes, modifiedSince: date) {
            alertMessage = "Cache has been cleared successfully."
            showingResultAlert = true
        }
    }
}

