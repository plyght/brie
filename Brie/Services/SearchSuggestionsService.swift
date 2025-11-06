import Foundation
import Combine

struct SearchSuggestion: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let type: SuggestionType
    
    enum SuggestionType {
        case suggestion
        case url
    }
}

@MainActor
class SearchSuggestionsService: ObservableObject {
    @Published var suggestions: [SearchSuggestion] = []
    private var cancellables = Set<AnyCancellable>()
    private var currentTask: Task<Void, Never>?
    
    func fetchSuggestions(for query: String) {
        currentTask?.cancel()
        
        guard !query.isEmpty else {
            suggestions = []
            return
        }
        
        if query.toURL() != nil {
            suggestions = [SearchSuggestion(text: query, type: .url)]
            return
        }
        
        currentTask = Task { @MainActor in
            do {
                let fetchedSuggestions = try await fetchGoogleSuggestions(query: query)
                if !Task.isCancelled {
                    self.suggestions = fetchedSuggestions
                }
            } catch {
                if !Task.isCancelled {
                    self.suggestions = []
                }
            }
        }
    }
    
    private func fetchGoogleSuggestions(query: String) async throws -> [SearchSuggestion] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://suggestqueries.google.com/complete/search?client=firefox&q=\(encodedQuery)") else {
            return []
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
              json.count > 1,
              let suggestions = json[1] as? [String] else {
            return []
        }
        
        return suggestions.prefix(8).map { SearchSuggestion(text: $0, type: .suggestion) }
    }
}

