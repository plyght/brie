import Foundation
import WebKit
import Combine

@MainActor
class WebViewService: NSObject, ObservableObject {
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentURL: URL?
    @Published var currentTitle: String?
    @Published var estimatedProgress: Double = 0
    
    nonisolated(unsafe) weak var webView: WKWebView?
    nonisolated(unsafe) private var observations = Set<AnyCancellable>()
    var onLinkClick: ((URL) -> Void)?
    var onCommandClick: ((URL) -> Void)?
    
    func configure(webView: WKWebView) {
        self.webView = webView
        webView.navigationDelegate = self
        
        observations.removeAll()
        
        webView.publisher(for: \.canGoBack)
            .sink { [weak self] value in
                self?.canGoBack = value
            }
            .store(in: &observations)
        
        webView.publisher(for: \.canGoForward)
            .sink { [weak self] value in
                self?.canGoForward = value
            }
            .store(in: &observations)
        
        webView.publisher(for: \.isLoading)
            .sink { [weak self] value in
                self?.isLoading = value
            }
            .store(in: &observations)
        
        webView.publisher(for: \.url)
            .sink { [weak self] value in
                self?.currentURL = value
            }
            .store(in: &observations)
        
        webView.publisher(for: \.title)
            .sink { [weak self] value in
                self?.currentTitle = value
            }
            .store(in: &observations)
        
        webView.publisher(for: \.estimatedProgress)
            .sink { [weak self] value in
                self?.estimatedProgress = value
            }
            .store(in: &observations)
    }
    
    deinit {
        observations.removeAll()
        webView?.navigationDelegate = nil
    }
    
    func load(url: URL) {
        webView?.load(URLRequest(url: url))
    }
    
    func load(urlString: String) {
        if let url = SearchEngineService.shared.processInput(urlString) {
            load(url: url)
        }
    }
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    func reload() {
        webView?.reload()
    }
    
    func stop() {
        webView?.stopLoading()
    }
}

extension WebViewService: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        if let url = webView.url {
            currentURL = url
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        DispatchQueue.main.async { [weak self] in
            self?.currentURL = webView.url
            self?.currentTitle = webView.title
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        print("Navigation failed: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        print("Provisional navigation failed: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let url = webView.url {
            currentURL = url
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url {
            if navigationAction.modifierFlags.contains(.command) {
                onCommandClick?(url)
                decisionHandler(.cancel)
                return
            } else {
                onLinkClick?(url)
            }
        }
        
        decisionHandler(.allow)
    }
}

