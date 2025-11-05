import Foundation
import UniformTypeIdentifiers

extension UTType {
    static let brieTrail = UTType(exportedAs: "com.brie.trail")
}

enum TrailType: String, Codable {
    case trail
    case subtrail
    case sidetrail
    case area
    case folder
    case note
}

struct KeyboardShortcuts {
    static let newTrail = "⌘T"
    static let newSubTrail = "⌥⌘T"
    static let newSideTrail = "⌥⇧⌘T"
    static let closeTrail = "⌘W"
    static let renameTrail = "⇧⌘L"
    static let collapseTrail = "⌘⇧◀︎"
    static let expandTrail = "⌘⇧▶︎"
    static let moveTrail = "⌥⌘⇧+arrows"
    static let settings = "⌘,"
    static let toggleSidebar = "⌥⌘S"
}

struct SearchEngines {
    static let google = SearchEngine(name: "Google", urlTemplate: "https://www.google.com/search?q=%@")
    static let bing = SearchEngine(name: "Bing", urlTemplate: "https://www.bing.com/search?q=%@")
    static let duckDuckGo = SearchEngine(name: "DuckDuckGo", urlTemplate: "https://duckduckgo.com/?q=%@")
    static let kagi = SearchEngine(name: "Kagi", urlTemplate: "https://kagi.com/search?q=%@")
    static let brave = SearchEngine(name: "Brave", urlTemplate: "https://search.brave.com/search?q=%@")
    
    static let all: [SearchEngine] = [google, bing, duckDuckGo, kagi, brave]
}

struct SearchEngine: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let urlTemplate: String
    
    func searchURL(for query: String) -> URL? {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = String(format: urlTemplate, encodedQuery)
        return URL(string: urlString)
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case urlTemplate
    }
}

