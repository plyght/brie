import SwiftUI
import CoreData

struct MainWindowView: View {
    @StateObject private var trailManager = TrailManager.shared
    @StateObject private var webViewService = WebViewService()
    @StateObject private var searchEngineService = SearchEngineService.shared
    @State private var selectedTrail: Trail?
    @State private var selectedPage: Page?
    @State private var isSidebarCollapsed = false
    @State private var currentURL: URL?
    @State private var addressText: String = ""
    @State private var showOmnibox: Bool = false
    @FocusState private var isOmniboxFocused: Bool
    
    var body: some View {
        HSplitView {
            SidebarView(
                trailManager: trailManager,
                selectedTrail: $selectedTrail,
                selectedPage: $selectedPage,
                isCollapsed: $isSidebarCollapsed
            )
            .frame(minWidth: isSidebarCollapsed ? 0 : 160, idealWidth: 180, maxWidth: 400)
            
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    BrowserView(webViewService: webViewService, initialURL: currentURL)
                    .onChange(of: selectedPage) { _, newPage in
                        if let url = newPage?.url {
                            webViewService.load(url: url)
                        }
                    }
                    .onChange(of: webViewService.currentURL) { _, newURL in
                        if let url = newURL,
                           let trail = selectedTrail,
                           selectedPage == nil {
                            let page = trailManager.createPage(trail: trail, url: url, title: webViewService.currentTitle)
                            selectedPage = page
                        } else if let page = selectedPage, let url = newURL {
                            trailManager.updatePage(page, title: webViewService.currentTitle)
                        }
                    }
                    .onChange(of: webViewService.currentTitle) { _, newTitle in
                        if let page = selectedPage, let title = newTitle {
                            trailManager.updatePage(page, title: title)
                        }
                    }
                }
                
                VStack {
                    FloatingOmniboxView(
                        webViewService: webViewService,
                        searchEngineService: searchEngineService,
                        isFocused: $isOmniboxFocused
                    )
                    .padding(.top, 80)
                    .padding(.horizontal, 40)
                    .opacity(showOmnibox ? 1 : 0)
                    .allowsHitTesting(showOmnibox)
                    .animation(.easeInOut(duration: 0.2), value: showOmnibox)
                    .onChange(of: isOmniboxFocused) { _, focused in
                        if !focused && showOmnibox {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showOmnibox = false
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    HStack(spacing: 8) {
                        Button(action: { webViewService.goBack() }) {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(!webViewService.canGoBack)
                        .buttonStyle(.borderless)
                        
                        Button(action: { webViewService.goForward() }) {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(!webViewService.canGoForward)
                        .buttonStyle(.borderless)
                        
                        Button(action: {
                            if webViewService.isLoading {
                                webViewService.stop()
                            } else {
                                webViewService.reload()
                            }
                        }) {
                            Image(systemName: webViewService.isLoading ? "xmark" : "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        if let url = webViewService.currentURL {
                            Image(systemName: url.scheme == "https" ? "lock.fill" : "lock.open.fill")
                                .font(.caption)
                                .foregroundColor(url.scheme == "https" ? .green : .gray)
                        }
                        
                        TextField("Search or enter address", text: $addressText)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                webViewService.load(urlString: addressText)
                            }
                            .onChange(of: webViewService.currentURL) { _, newURL in
                                if let url = newURL {
                                    addressText = url.absoluteString
                                }
                            }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(6)
                    .frame(maxWidth: 600)
                }
            }
        }
        .onKeyPress(KeyEquivalent("t"), modifiers: .command) {
            showOmnibox = true
            isOmniboxFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                isSidebarCollapsed.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .collapseTrail)) { _ in
            if let trail = selectedTrail, !trail.isCollapsed {
                trailManager.toggleTrailCollapsed(trail)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .expandTrail)) { _ in
            if let trail = selectedTrail, trail.isCollapsed {
                trailManager.toggleTrailCollapsed(trail)
            }
        }
        .onAppear {
            webViewService.onLinkClick = { [trailManager, webViewService] url in
                guard let trail = self.selectedTrail else { return }
                let newPage = trailManager.createPage(trail: trail, url: url, title: url.absoluteString)
                DispatchQueue.main.async {
                    self.selectedPage = newPage
                }
            }
            
            webViewService.onCommandClick = { [trailManager] url in
                guard let trail = self.selectedTrail else { return }
                _ = trailManager.createPage(trail: trail, url: url, title: url.absoluteString)
            }
            
            if trailManager.trails.isEmpty {
                let firstTrail = trailManager.createTrail(name: "Welcome")
                selectedTrail = firstTrail
                if let url = URL(string: "https://www.google.com") {
                    currentURL = url
                    webViewService.load(url: url)
                    addressText = url.absoluteString
                }
            }
            
            if let url = webViewService.currentURL {
                addressText = url.absoluteString
            }
        }
    }
}

