import SwiftUI

struct BrowserToolbar: View {
    @ObservedObject var webViewService: WebViewService
    
    var body: some View {
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
            
            if webViewService.isLoading {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

