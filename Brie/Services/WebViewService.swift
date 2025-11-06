import Foundation
import WebKit
import Combine
import AppKit

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
        webView.uiDelegate = self
        
        let userContentController = webView.configuration.userContentController
        userContentController.add(self, name: "contextMenuHandler")
        
        let script = WKUserScript(
            source: """
            document.addEventListener('contextmenu', function(e) {
                var link = e.target.closest('a');
                if (link && link.href) {
                    window.webkit.messageHandlers.contextMenuHandler.postMessage({
                        type: 'link',
                        url: link.href,
                        x: e.clientX,
                        y: e.clientY
                    });
                }
            }, true);
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        webView.configuration.userContentController.addUserScript(script)
        
        observations.removeAll()
        
        webView.publisher(for: \.canGoBack)
            .debounce(for: .milliseconds(10), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .assign(to: \.canGoBack, on: self)
            .store(in: &observations)
        
        webView.publisher(for: \.canGoForward)
            .debounce(for: .milliseconds(10), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .assign(to: \.canGoForward, on: self)
            .store(in: &observations)
        
        webView.publisher(for: \.isLoading)
            .debounce(for: .milliseconds(10), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &observations)
        
        webView.publisher(for: \.url)
            .debounce(for: .milliseconds(10), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .compactMap { $0 }
            .assign(to: \.currentURL, on: self)
            .store(in: &observations)
        
        webView.publisher(for: \.title)
            .debounce(for: .milliseconds(10), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .assign(to: \.currentTitle, on: self)
            .store(in: &observations)
        
        webView.publisher(for: \.estimatedProgress)
            .debounce(for: .milliseconds(10), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .assign(to: \.estimatedProgress, on: self)
            .store(in: &observations)
    }
    
    deinit {
        observations.removeAll()
        Task { @MainActor [weak webView] in
            webView?.navigationDelegate = nil
        }
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
    @MainActor
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.isLoading = true
        if let url = webView.url {
            self.currentURL = url
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.isLoading = false
        self.currentURL = webView.url
        self.currentTitle = webView.title
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.isLoading = false
        print("Navigation failed: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.isLoading = false
        print("Provisional navigation failed: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let url = webView.url {
            self.currentURL = url
        }
    }
    
    @MainActor
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url {
            if navigationAction.modifierFlags.contains(.command) {
                self.onCommandClick?(url)
                decisionHandler(.cancel, preferences)
                return
            } else {
                self.onLinkClick?(url)
            }
        }
        
        preferences.allowsContentJavaScript = true
        decisionHandler(.allow, preferences)
    }
}

extension WebViewService: WKScriptMessageHandler {
    nonisolated func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageName = message.name
        let messageBody = message.body
        
        guard messageName == "contextMenuHandler",
              let body = messageBody as? [String: Any],
              let urlString = body["url"] as? String,
              let url = URL(string: urlString) else {
            return
        }
        
        Task { @MainActor in
            let menu = NSMenu()
            
            let openInNewTab = NSMenuItem(
                title: "Open Link in New Tab",
                action: #selector(handleOpenInNewTab(_:)),
                keyEquivalent: ""
            )
            openInNewTab.target = self
            openInNewTab.representedObject = url
            menu.addItem(openInNewTab)
            
            let copyLink = NSMenuItem(
                title: "Copy Link",
                action: #selector(handleCopyLink(_:)),
                keyEquivalent: ""
            )
            copyLink.target = self
            copyLink.representedObject = url
            menu.addItem(copyLink)
            
            if let event = NSApp.currentEvent {
                NSMenu.popUpContextMenu(menu, with: event, for: message.webView ?? NSView())
            }
        }
    }
    
    @objc private func handleOpenInNewTab(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        onCommandClick?(url)
    }
    
    @objc private func handleCopyLink(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
    }
}

extension WebViewService: WKUIDelegate {
    @MainActor
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = frame.securityOrigin.host
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational
        alert.runModal()
        completionHandler()
    }
    
    @MainActor
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = frame.securityOrigin.host
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational
        let response = alert.runModal()
        completionHandler(response == .alertFirstButtonReturn)
    }
    
    @MainActor
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = NSAlert()
        alert.messageText = frame.securityOrigin.host
        alert.informativeText = prompt
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputTextField.stringValue = defaultText ?? ""
        alert.accessoryView = inputTextField
        
        alert.window.initialFirstResponder = inputTextField
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            completionHandler(inputTextField.stringValue)
        } else {
            completionHandler(nil)
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

