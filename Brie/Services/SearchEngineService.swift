import Foundation
import Combine

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

@MainActor
class SearchEngineService: ObservableObject {
    static let shared = SearchEngineService()
    
    @Published var currentSearchEngine: SearchEngine
    @Published var availableSearchEngines: [SearchEngine]
    
    private let defaultsKey = "selectedSearchEngineName"
    
    init() {
        self.availableSearchEngines = SearchEngines.all
        
        if let savedName = UserDefaults.standard.string(forKey: defaultsKey),
           let engine = SearchEngines.all.first(where: { $0.name == savedName }) {
            self.currentSearchEngine = engine
        } else {
            self.currentSearchEngine = SearchEngines.google
        }
    }
    
    func setSearchEngine(_ engine: SearchEngine) {
        currentSearchEngine = engine
        UserDefaults.standard.set(engine.name, forKey: defaultsKey)
    }
    
    func searchURL(for query: String) -> URL? {
        return currentSearchEngine.searchURL(for: query)
    }
    
    func processInput(_ input: String) -> URL? {
        if let url = input.toURL() {
            return url
        }
        
        return searchURL(for: input)
    }
    
    func generateSearchResults(query: String) -> [SearchResult] {
        var results: [SearchResult] = []
        
        if let url = query.toURL() {
            results.append(SearchResult(
                title: "Open URL",
                url: query,
                icon: "link",
                type: .url
            ))
        }
        
        results.append(SearchResult(
            title: "Search \(currentSearchEngine.name) for \"\(query)\"",
            url: query,
            icon: "magnifyingglass",
            type: .searchSuggestion
        ))
        
        for engine in availableSearchEngines where engine.name != currentSearchEngine.name {
            results.append(SearchResult(
                title: "Search \(engine.name) for \"\(query)\"",
                url: query,
                icon: "magnifyingglass",
                type: .searchSuggestion
            ))
        }
        
        return Array(results.prefix(6))
    }
}

