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
    
    nonisolated func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
        return await MainActor.run {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                if navigationAction.modifierFlags.contains(.command) {
                    self.onCommandClick?(url)
                    preferences.allowsContentJavaScript = true
                    return (.cancel, preferences)
                } else {
                    self.onLinkClick?(url)
                }
            }
            
            preferences.allowsContentJavaScript = true
            return (.allow, preferences)
        }
    }
}

extension WebViewService: WKScriptMessageHandler {
    nonisolated func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        Task { @MainActor in
            guard message.name == "contextMenuHandler",
                  let body = message.body as? [String: Any],
                  let urlString = body["url"] as? String,
                  let url = URL(string: urlString) else {
                return
            }
            
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
    nonisolated func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo) async {
        await MainActor.run {
            let alert = NSAlert()
            alert.messageText = frame.securityOrigin.host
            alert.informativeText = message
            alert.addButton(withTitle: "OK")
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
    
    nonisolated func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo) async -> Bool {
        await MainActor.run {
            let alert = NSAlert()
            alert.messageText = frame.securityOrigin.host
            alert.informativeText = message
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .informational
            let response = alert.runModal()
            return response == .alertFirstButtonReturn
        }
    }
    
    nonisolated func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo) async -> String? {
        await MainActor.run {
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
                return inputTextField.stringValue
            } else {
                return nil
            }
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

