import SwiftUI
import WebKit

struct BrowserView: NSViewRepresentable {
    @ObservedObject var webViewService: WebViewService
    let initialURL: URL?
    
    init(webViewService: WebViewService, initialURL: URL? = nil) {
        self.webViewService = webViewService
        self.initialURL = initialURL
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsMagnification = true
        
        webViewService.configure(webView: webView)
        
        if let url = initialURL {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
    }
    
    static func dismantleNSView(_ webView: WKWebView, coordinator: ()) {
        webView.stopLoading()
        webView.configuration.processPool = WKProcessPool()
    }
}

