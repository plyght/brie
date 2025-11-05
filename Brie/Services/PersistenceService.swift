import Foundation
import CoreData

@MainActor
class PersistenceService: ObservableObject {
    static let shared = PersistenceService()
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }
    
    func saveWebViewState(for page: Page, snapshot: Data?) {
        page.webViewSnapshot = snapshot
        CoreDataStack.shared.saveContext()
    }
    
    func restoreWebViewState(for page: Page) -> Data? {
        return page.webViewSnapshot
    }
    
    func exportData() -> Data? {
        let trailManager = TrailManager.shared
        let markdown = trailManager.exportTrailsToMarkdown()
        return markdown.data(using: .utf8)
    }
    
    func importData(from data: Data) throws {
    }
    
    func clearAllData() throws {
        let entities = ["Trail", "Page", "Area", "Folder", "Note"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            try context.persistentStoreCoordinator?.execute(deleteRequest, with: context)
        }
        
        CoreDataStack.shared.saveContext()
    }
    
    func backupData(to url: URL) throws {
        guard let data = exportData() else {
            throw NSError(domain: "PersistenceService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to export data"])
        }
        
        try data.write(to: url)
    }
}

