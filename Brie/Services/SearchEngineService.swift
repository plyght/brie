import Foundation
import Combine

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
}

