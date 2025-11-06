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
    @Published var customSearchEngines: [SearchEngine] = []
    
    private let defaultsKey = "selectedSearchEngineName"
    private let customEnginesKey = "customSearchEngines"
    
    init() {
        let loadedCustomEngines = Self.loadCustomEngines()
        self.customSearchEngines = loadedCustomEngines
        self.availableSearchEngines = SearchEngines.all + loadedCustomEngines
        
        if let savedName = UserDefaults.standard.string(forKey: defaultsKey),
           let engine = (SearchEngines.all + loadedCustomEngines).first(where: { $0.name == savedName }) {
            self.currentSearchEngine = engine
        } else {
            self.currentSearchEngine = SearchEngines.google
        }
    }
    
    func setSearchEngine(_ engine: SearchEngine) {
        currentSearchEngine = engine
        UserDefaults.standard.set(engine.name, forKey: defaultsKey)
    }
    
    func addCustomEngine(name: String, urlTemplate: String) {
        let engine = SearchEngine(name: name, urlTemplate: urlTemplate)
        customSearchEngines.append(engine)
        availableSearchEngines = SearchEngines.all + customSearchEngines
        saveCustomEngines()
    }
    
    func removeCustomEngine(_ engine: SearchEngine) {
        customSearchEngines.removeAll { $0.id == engine.id }
        availableSearchEngines = SearchEngines.all + customSearchEngines
        saveCustomEngines()
        
        if currentSearchEngine.id == engine.id {
            currentSearchEngine = SearchEngines.google
            UserDefaults.standard.set(currentSearchEngine.name, forKey: defaultsKey)
        }
    }
    
    func updateCustomEngine(_ engine: SearchEngine, name: String, urlTemplate: String) {
        if let index = customSearchEngines.firstIndex(where: { $0.id == engine.id }) {
            customSearchEngines[index] = SearchEngine(name: name, urlTemplate: urlTemplate)
            availableSearchEngines = SearchEngines.all + customSearchEngines
            saveCustomEngines()
        }
    }
    
    private func saveCustomEngines() {
        if let encoded = try? JSONEncoder().encode(customSearchEngines) {
            UserDefaults.standard.set(encoded, forKey: customEnginesKey)
        }
    }
    
    private static func loadCustomEngines() -> [SearchEngine] {
        guard let data = UserDefaults.standard.data(forKey: "customSearchEngines"),
              let engines = try? JSONDecoder().decode([SearchEngine].self, from: data) else {
            return []
        }
        return engines
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
        
        if query.toURL() != nil {
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

