import SwiftUI
import WebKit

struct SettingsView: View {
    @StateObject private var searchEngineService = SearchEngineService.shared
    @AppStorage("showSidebarOnLaunch") private var showSidebarOnLaunch = true
    @AppStorage("restorePreviousSession") private var restorePreviousSession = true
    
    var body: some View {
        TabView {
            GeneralSettingsView(
                searchEngineService: searchEngineService,
                showSidebarOnLaunch: $showSidebarOnLaunch,
                restorePreviousSession: $restorePreviousSession
            )
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
            
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
            
            ExtensionsSettingsView()
                .tabItem {
                    Label("Extensions", systemImage: "puzzlepiece.extension")
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
        .frame(width: 650, height: 500)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var searchEngineService: SearchEngineService
    @Binding var showSidebarOnLaunch: Bool
    @Binding var restorePreviousSession: Bool
    @State private var showingAddEngine = false
    @State private var editingEngine: SearchEngine?
    @State private var hoveredEngine: SearchEngine?
    
    var body: some View {
        Form {
            Section {
                Picker("Default search engine:", selection: $searchEngineService.currentSearchEngine) {
                    ForEach(searchEngineService.availableSearchEngines) { engine in
                        Text(engine.name).tag(engine)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Search Engine")
                    .font(.headline)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Custom Search Engines")
                            .font(.subheadline)
                        Spacer()
                        Button(action: { showingAddEngine = true }) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    if searchEngineService.customSearchEngines.isEmpty {
                        Text("No custom search engines")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(searchEngineService.customSearchEngines) { engine in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(engine.name)
                                        .font(.body)
                                    Text(engine.urlTemplate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Button(action: { editingEngine = engine }) {
                                    Image(systemName: "pencil")
                                }
                                .buttonStyle(.borderless)
                                Button(action: { searchEngineService.removeCustomEngine(engine) }) {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddEngine) {
                CustomSearchEngineEditor(
                    searchEngineService: searchEngineService,
                    engine: nil,
                    onDismiss: { showingAddEngine = false }
                )
            }
            .sheet(item: $editingEngine) { engine in
                CustomSearchEngineEditor(
                    searchEngineService: searchEngineService,
                    engine: engine,
                    onDismiss: { editingEngine = nil }
                )
            }
            
            Section {
                Toggle("Show sidebar on launch", isOn: $showSidebarOnLaunch)
                Toggle("Restore previous session", isOn: $restorePreviousSession)
            } header: {
                Text("On Launch")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("abbreviateURLs") private var abbreviateURLs = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Abbreviate URLs in address bar", isOn: $abbreviateURLs)
                Text("When enabled, long URLs will be shortened to show only the domain and last path segment")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Interface")
                    .font(.headline)
            }
            
            Section {
                Text("Brie uses your system appearance settings. To change the appearance, go to System Settings > Appearance")
                    .font(.callout)
                    .foregroundColor(.secondary)
            } header: {
                Text("System Appearance")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct KeyboardShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section {
                ShortcutRow(action: "New Trail", shortcut: KeyboardShortcuts.newTrail)
                ShortcutRow(action: "New SubTrail", shortcut: KeyboardShortcuts.newSubTrail)
                ShortcutRow(action: "New SideTrail", shortcut: KeyboardShortcuts.newSideTrail)
                ShortcutRow(action: "Close Trail/Page", shortcut: KeyboardShortcuts.closeTrail)
                ShortcutRow(action: "Rename Trail", shortcut: KeyboardShortcuts.renameTrail)
            } header: {
                Text("Trail Management")
                    .font(.headline)
            }
            
            Section {
                ShortcutRow(action: "Toggle Sidebar", shortcut: KeyboardShortcuts.toggleSidebar)
                ShortcutRow(action: "Focus Address Bar", shortcut: "⌘L")
                ShortcutRow(action: "Collapse Trail", shortcut: KeyboardShortcuts.collapseTrail)
                ShortcutRow(action: "Expand Trail", shortcut: KeyboardShortcuts.expandTrail)
            } header: {
                Text("Navigation")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct ShortcutRow: View {
    let action: String
    let shortcut: String
    
    var body: some View {
        HStack {
            Text(action)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}

struct ExtensionsSettingsView: View {
    @StateObject private var authService = AuthenticationService.shared
    @AppStorage("extensionsEnabled") private var extensionsEnabled = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Safari Extensions", isOn: $extensionsEnabled)
                Text("Allow Safari App Extensions to interact with web content")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.extensions") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Label("Open Safari Extensions Settings", systemImage: "gearshape.2")
                }
                .buttonStyle(.link)
            } header: {
                Text("Extension Support")
                    .font(.headline)
            }
            
            Section {
                HStack {
                    Text("Biometric Authentication")
                    Spacer()
                    Text(authService.hasBiometrics ? "\(authService.biometricTypeString) available" : "Not available")
                        .foregroundColor(authService.hasBiometrics ? .green : .secondary)
                }
                Text("Websites can request biometric authentication for passkeys and WebAuthn")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Authentication")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
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
            Section {
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
                
                Button(role: .destructive, action: {
                    showingClearDataAlert = true
                }) {
                    Label("Clear All Data", systemImage: "trash")
                }
                Text("This will permanently delete all trails, pages, and notes")
                    .font(.caption)
                    .foregroundColor(.red)
            } header: {
                Text("Data Management")
                    .font(.headline)
            }
            
            Section {
                Button(action: {
                    showingClearCacheAlert = true
                }) {
                    Label("Clear Cache", systemImage: "trash.circle")
                }
                Text("Clear website data and cache. You may need to log in to websites again")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Storage")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
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

struct CustomSearchEngineEditor: View {
    @ObservedObject var searchEngineService: SearchEngineService
    let engine: SearchEngine?
    let onDismiss: () -> Void
    
    @State private var name: String = ""
    @State private var urlTemplate: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var isEditing: Bool {
        engine != nil
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isEditing ? "Edit Search Engine" : "Add Custom Search Engine")
                .font(.title2)
                .fontWeight(.semibold)
            
            Form {
                TextField("Name:", text: $name)
                TextField("URL Template:", text: $urlTemplate)
                Text("Use %@ as a placeholder for the search query. Example: https://www.google.com/search?q=%@")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button(isEditing ? "Save" : "Add") {
                    saveEngine()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 450, height: 280)
        .onAppear {
            if let engine = engine {
                name = engine.name
                urlTemplate = engine.urlTemplate
            }
        }
    }
    
    private func saveEngine() {
        guard !name.isEmpty else {
            errorMessage = "Please enter a name for the search engine."
            showError = true
            return
        }
        
        guard !urlTemplate.isEmpty else {
            errorMessage = "Please enter a URL template."
            showError = true
            return
        }
        
        guard urlTemplate.contains("%@") else {
            errorMessage = "URL template must contain %@ as a placeholder."
            showError = true
            return
        }
        
        guard urlTemplate.hasPrefix("http://") || urlTemplate.hasPrefix("https://") else {
            errorMessage = "URL template must start with http:// or https://"
            showError = true
            return
        }
        
        if let engine = engine {
            searchEngineService.updateCustomEngine(engine, name: name, urlTemplate: urlTemplate)
        } else {
            searchEngineService.addCustomEngine(name: name, urlTemplate: urlTemplate)
        }
        
        onDismiss()
    }
}
