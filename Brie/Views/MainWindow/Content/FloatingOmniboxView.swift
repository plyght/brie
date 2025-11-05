import SwiftUI

struct FloatingOmniboxView: View {
    @ObservedObject var webViewService: WebViewService
    @ObservedObject var searchEngineService: SearchEngineService
    @FocusState.Binding var isFocused: Bool
    @State private var searchText: String = ""
    @State private var showingResults: Bool = false
    @State private var searchResults: [SearchResult] = []
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if let url = webViewService.currentURL {
                    Image(systemName: url.scheme == "https" ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 13))
                        .foregroundColor(url.scheme == "https" ? .green : .secondary)
                } else {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                TextField("Search or enter address", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .focused($isFocused)
                    .onSubmit {
                        handleSubmit()
                    }
                    .onChange(of: searchText) { _, newValue in
                        updateSearchResults(query: newValue)
                    }
                    .onChange(of: webViewService.currentURL) { _, newURL in
                        if !isFocused, let url = newURL {
                            searchText = url.absoluteString
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchResults = []
                        showingResults = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            if showingResults && !searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(searchResults) { result in
                        SearchResultRow(result: result) {
                            selectResult(result)
                        }
                    }
                }
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: 600)
        .onChange(of: isFocused) { _, focused in
            if focused {
                showingResults = !searchText.isEmpty
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showingResults = false
                }
            }
        }
        .onAppear {
            if let url = webViewService.currentURL {
                searchText = url.absoluteString
            }
        }
    }
    
    private func handleSubmit() {
        webViewService.load(urlString: searchText)
        isFocused = false
        showingResults = false
    }
    
    private func updateSearchResults(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            showingResults = false
            return
        }
        
        searchResults = searchEngineService.generateSearchResults(query: query)
        showingResults = true
    }
    
    private func selectResult(_ result: SearchResult) {
        searchText = result.url
        handleSubmit()
    }
}

struct SearchResult: Identifiable {
    let id = UUID()
    let title: String
    let url: String
    let icon: String
    let type: ResultType
    
    enum ResultType {
        case url
        case searchSuggestion
        case history
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: result.icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(result.url)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

