import SwiftUI
import CoreData

struct MainWindowView: View {
    @StateObject private var trailManager = TrailManager.shared
    @StateObject private var webViewService = WebViewService()
    @State private var selectedTrail: Trail?
    @State private var selectedPage: Page?
    @State private var isSidebarCollapsed = false
    @State private var currentURL: URL?
    
    var body: some View {
        HSplitView {
            SidebarView(
                trailManager: trailManager,
                selectedTrail: $selectedTrail,
                selectedPage: $selectedPage,
                isCollapsed: $isSidebarCollapsed
            )
            .frame(minWidth: isSidebarCollapsed ? 0 : 200, idealWidth: 250, maxWidth: 400)
            
            VStack(spacing: 0) {
                BrowserAddressBar(webViewService: webViewService)
                
                Divider()
                
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
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
            withAnimation {
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
            
            if trailManager.trails.isEmpty {
                let firstTrail = trailManager.createTrail(name: "Welcome")
                selectedTrail = firstTrail
                if let url = URL(string: "https://www.google.com") {
                    currentURL = url
                    webViewService.load(url: url)
                }
            }
        }
    }
}

