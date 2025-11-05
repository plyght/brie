import SwiftUI
import WebKit

struct SettingsView: View {
    @StateObject private var searchEngineService = SearchEngineService.shared
    
    var body: some View {
        TabView {
            GeneralSettingsView(searchEngineService: searchEngineService)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            KeyboardShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
            
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var searchEngineService: SearchEngineService
    
    var body: some View {
        Form {
            Section(header: Text("Search Engine")) {
                Picker("Default Search Engine", selection: $searchEngineService.currentSearchEngine) {
                    ForEach(searchEngineService.availableSearchEngines) { engine in
                        Text(engine.name).tag(engine)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section(header: Text("Appearance")) {
                Toggle("Show sidebar on launch", isOn: .constant(true))
                Toggle("Restore previous session", isOn: .constant(true))
            }
        }
        .padding()
    }
}

struct KeyboardShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Trail Management")) {
                HStack {
                    Text("New Trail")
                    Spacer()
                    Text(KeyboardShortcuts.newTrail)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("New SubTrail")
                    Spacer()
                    Text(KeyboardShortcuts.newSubTrail)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("New SideTrail")
                    Spacer()
                    Text(KeyboardShortcuts.newSideTrail)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Close Trail/Page")
                    Spacer()
                    Text(KeyboardShortcuts.closeTrail)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Rename Trail")
                    Spacer()
                    Text(KeyboardShortcuts.renameTrail)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Navigation")) {
                HStack {
                    Text("Toggle Sidebar")
                    Spacer()
                    Text(KeyboardShortcuts.toggleSidebar)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Collapse Trail")
                    Spacer()
                    Text(KeyboardShortcuts.collapseTrail)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Expand Trail")
                    Spacer()
                    Text(KeyboardShortcuts.expandTrail)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

struct AdvancedSettingsView: View {
    @State private var showingClearDataAlert = false
    @State private var showingClearCacheAlert = false
    @State private var alertMessage: String?
    @State private var showingResultAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Data Management")) {
                Button("Export Trails to Markdown") {
                    let markdown = TrailManager.shared.exportTrailsToMarkdown()
                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.plainText]
                    panel.nameFieldStringValue = "trails.md"
                    panel.begin { response in
                        if response == .OK, let url = panel.url {
                            try? markdown.write(to: url, atomically: true, encoding: .utf8)
                        }
                    }
                }
                
                Button("Clear All Data", role: .destructive) {
                    showingClearDataAlert = true
                }
            }
            
            Section(header: Text("Storage")) {
                Button("Clear Cache") {
                    showingClearCacheAlert = true
                }
            }
        }
        .padding()
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

