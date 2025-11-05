import SwiftUI

struct BrowserAddressBar: View {
    @ObservedObject var webViewService: WebViewService
    @State private var addressText: String = ""
    @FocusState private var isAddressFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            BrowserToolbar(webViewService: webViewService)
            
            HStack(spacing: 8) {
                if let url = webViewService.currentURL {
                    Image(systemName: url.scheme == "https" ? "lock.fill" : "lock.open.fill")
                        .font(.caption)
                        .foregroundColor(url.scheme == "https" ? .green : .gray)
                }
                
                TextField("Search or enter address", text: $addressText)
                    .textFieldStyle(.plain)
                    .focused($isAddressFocused)
                    .onSubmit {
                        webViewService.load(urlString: addressText)
                        isAddressFocused = false
                    }
                    .onChange(of: webViewService.currentURL) { _, newURL in
                        if !isAddressFocused, let url = newURL {
                            addressText = url.absoluteString
                        }
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            if let url = webViewService.currentURL {
                addressText = url.absoluteString
            }
        }
    }
}

