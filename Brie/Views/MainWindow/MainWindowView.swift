import SwiftUI
import CoreData

struct MainWindowView: View {
    @StateObject private var trailManager = TrailManager.shared
    @StateObject private var webViewService = WebViewService()
    @StateObject private var searchEngineService = SearchEngineService.shared
    @State private var selectedTrail: Trail?
    @State private var selectedPage: Page?
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .automatic
    @State private var currentURL: URL?
    @State private var showOmnibox: Bool = false
    @State private var searchText: String = ""
    @FocusState private var isOmniboxFocused: Bool
    @FocusState private var isSearchFocused: Bool
    @AppStorage("abbreviateURLs") private var abbreviateURLs = true
    
    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            SidebarView(
                trailManager: trailManager,
                selectedTrail: $selectedTrail,
                selectedPage: $selectedPage
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 400)
        } detail: {
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
                        } else if let page = selectedPage, newURL != nil {
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
                    HStack(spacing: 6) {
                        Button(action: { webViewService.goBack() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13))
                                .frame(width: 20, height: 20)
                        }
                        .disabled(!webViewService.canGoBack)
                        .buttonStyle(.borderless)
                        .frame(minWidth: 28, minHeight: 28)
                        .help("Go Back")
                        
                        Button(action: { webViewService.goForward() }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .frame(width: 20, height: 20)
                        }
                        .disabled(!webViewService.canGoForward)
                        .buttonStyle(.borderless)
                        .frame(minWidth: 28, minHeight: 28)
                        .help("Go Forward")
                        
                        Button(action: {
                            if webViewService.isLoading {
                                webViewService.stop()
                            } else {
                                webViewService.reload()
                            }
                        }) {
                            Image(systemName: webViewService.isLoading ? "xmark" : "arrow.clockwise")
                                .font(.system(size: 13))
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(.borderless)
                        .frame(minWidth: 28, minHeight: 28)
                        .help(webViewService.isLoading ? "Stop Loading" : "Reload")
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        if let url = webViewService.currentURL {
                            Image(systemName: url.scheme == "https" ? "lock.fill" : "lock.open.fill")
                                .font(.system(size: 11))
                                .foregroundColor(url.scheme == "https" ? .green : .secondary)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        TextField("Search or enter address", text: $searchText)
                            .textFieldStyle(.plain)
                            .focused($isSearchFocused)
                            .multilineTextAlignment(isSearchFocused ? .leading : .center)
                            .onSubmit {
                                webViewService.load(urlString: searchText)
                                isSearchFocused = false
                            }
                        
                        if !searchText.isEmpty && isSearchFocused {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Clear")
                        } else {
                            Color.clear.frame(width: 12)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .frame(minWidth: 400, maxWidth: .infinity)
                }
            }
            .onChange(of: webViewService.currentURL) { _, newURL in
                if let url = newURL, !isSearchFocused {
                    if abbreviateURLs {
                        searchText = url.abbreviated()
                    } else {
                        searchText = url.absoluteString
                    }
                }
            }
            .onChange(of: isSearchFocused) { _, focused in
                if focused, let url = webViewService.currentURL {
                    searchText = url.absoluteString
                } else if !focused, let url = webViewService.currentURL {
                    if abbreviateURLs {
                        searchText = url.abbreviated()
                    } else {
                        searchText = url.absoluteString
                    }
                }
            }
            .onChange(of: abbreviateURLs) { _, shouldAbbreviate in
                if !isSearchFocused, let url = webViewService.currentURL {
                    if shouldAbbreviate {
                        searchText = url.abbreviated()
                    } else {
                        searchText = url.absoluteString
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onKeyPress(KeyEquivalent("t"), modifiers: .command) {
            showOmnibox = true
            isOmniboxFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                sidebarVisibility = sidebarVisibility == .doubleColumn ? .detailOnly : .doubleColumn
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
            webViewService.onLinkClick = { [trailManager] url in
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
                    if abbreviateURLs {
                        searchText = url.abbreviated()
                    } else {
                        searchText = url.absoluteString
                    }
                }
            }
            
            if let url = webViewService.currentURL, searchText.isEmpty {
                if abbreviateURLs {
                    searchText = url.abbreviated()
                } else {
                    searchText = url.absoluteString
                }
            }
        }
    }
}

