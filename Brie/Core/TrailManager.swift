import CoreData
import Foundation
import Combine

@MainActor
class TrailManager: ObservableObject {
    static let shared = TrailManager()
    
    let context: NSManagedObjectContext
    @Published var selectedTrail: Trail?
    @Published var selectedPage: Page?
    @Published var trails: [Trail] = []
    @Published var areas: [Area] = []
    @Published var folders: [Folder] = []
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
        fetchAllData()
    }
    
    func fetchAllData() {
        fetchTrails()
        fetchAreas()
        fetchFolders()
    }
    
    func fetchTrails() {
        let request: NSFetchRequest<Trail> = Trail.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Trail.orderIndex, ascending: true)]
        request.predicate = NSPredicate(format: "parentTrail == nil AND area == nil AND folder == nil")
        
        do {
            trails = try context.fetch(request)
            objectWillChange.send()
        } catch {
            print("Error fetching trails: \(error.localizedDescription)")
            NotificationCenter.default.post(
                name: .coreDataSaveError,
                object: nil,
                userInfo: ["error": error, "operation": "fetch trails"]
            )
        }
    }
    
    func fetchAreas() {
        let request: NSFetchRequest<Area> = Area.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Area.orderIndex, ascending: true)]
        
        do {
            areas = try context.fetch(request)
            objectWillChange.send()
        } catch {
            print("Error fetching areas: \(error.localizedDescription)")
            NotificationCenter.default.post(
                name: .coreDataSaveError,
                object: nil,
                userInfo: ["error": error, "operation": "fetch areas"]
            )
        }
    }
    
    func fetchFolders() {
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Folder.orderIndex, ascending: true)]
        
        do {
            folders = try context.fetch(request)
            objectWillChange.send()
        } catch {
            print("Error fetching folders: \(error.localizedDescription)")
            NotificationCenter.default.post(
                name: .coreDataSaveError,
                object: nil,
                userInfo: ["error": error, "operation": "fetch folders"]
            )
        }
    }
    
    func validateTrailName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 100
    }
    
    func validateURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
    
    @discardableResult
    func createTrail(name: String? = nil, type: TrailType = .trail, parent: Trail? = nil, area: Area? = nil, folder: Folder? = nil) -> Trail {
        var trailName = name ?? "Untitled Trail"
        if !validateTrailName(trailName) {
            trailName = "Untitled Trail"
        }
        
        let trail = Trail(context: context)
        trail.id = UUID()
        trail.name = trailName
        trail.type = type.rawValue
        trail.createdAt = Date()
        trail.updatedAt = Date()
        trail.isCollapsed = false
        trail.orderIndex = Int32((parent?.childTrails?.count ?? 0) + (area?.trails?.count ?? 0) + (folder?.trails?.count ?? 0))
        
        if let parent = parent {
            trail.parentTrail = parent
        } else if let area = area {
            trail.area = area
        } else if let folder = folder {
            trail.folder = folder
        }
        
        saveContext()
        fetchAllData()
        return trail
    }
    
    @discardableResult
    func createSubTrail(parent: Trail, name: String? = nil) -> Trail {
        return createTrail(name: name, type: .subtrail, parent: parent)
    }
    
    @discardableResult
    func createSideTrail(parent: Trail, name: String? = nil) -> Trail {
        let sideTrail = createTrail(name: name, type: .sidetrail, parent: parent.parentTrail, area: parent.area, folder: parent.folder)
        if let parentIndex = parent.orderIndex as Int32? {
            sideTrail.orderIndex = parentIndex + 1
        }
        saveContext()
        fetchAllData()
        return sideTrail
    }
    
    @discardableResult
    func createArea(name: String, icon: String? = nil) -> Area {
        let area = Area(context: context)
        area.id = UUID()
        area.name = name
        area.icon = icon
        area.createdAt = Date()
        area.orderIndex = Int32(areas.count)
        
        saveContext()
        fetchAreas()
        return area
    }
    
    @discardableResult
    func createFolder(name: String, icon: String? = nil) -> Folder {
        let folder = Folder(context: context)
        folder.id = UUID()
        folder.name = name
        folder.icon = icon
        folder.createdAt = Date()
        folder.orderIndex = Int32(folders.count)
        
        saveContext()
        fetchFolders()
        return folder
    }
    
    @discardableResult
    func createPage(trail: Trail, url: URL, title: String? = nil) -> Page {
        let page = Page(context: context)
        page.id = UUID()
        page.url = url
        page.title = title ?? url.absoluteString
        page.createdAt = Date()
        page.isActive = false
        page.trail = trail
        page.orderIndex = Int32(trail.pages?.count ?? 0)
        
        saveContext()
        return page
    }
    
    @discardableResult
    func createNote(trail: Trail, content: String? = nil) -> Note {
        let note = Note(context: context)
        note.id = UUID()
        note.content = content ?? ""
        note.createdAt = Date()
        note.updatedAt = Date()
        note.trail = trail
        
        saveContext()
        return note
    }
    
    func deleteTrail(_ trail: Trail) {
        context.delete(trail)
        saveContext()
        fetchAllData()
    }
    
    func deletePage(_ page: Page) {
        context.delete(page)
        saveContext()
    }
    
    func deleteArea(_ area: Area) {
        context.delete(area)
        saveContext()
        fetchAreas()
    }
    
    func deleteFolder(_ folder: Folder) {
        context.delete(folder)
        saveContext()
        fetchFolders()
    }
    
    func updateTrail(_ trail: Trail, name: String? = nil, icon: String? = nil, isCollapsed: Bool? = nil) {
        if let name = name {
            if validateTrailName(name) {
                trail.name = name
            }
        }
        if let icon = icon {
            trail.icon = icon
        }
        if let isCollapsed = isCollapsed {
            trail.isCollapsed = isCollapsed
        }
        trail.updatedAt = Date()
        saveContext()
    }
    
    func updatePage(_ page: Page, title: String? = nil, icon: String? = nil, isActive: Bool? = nil) {
        if let title = title {
            page.title = title
        }
        if let icon = icon {
            page.icon = icon
        }
        if let isActive = isActive {
            page.isActive = isActive
        }
        saveContext()
    }
    
    func moveTrail(_ trail: Trail, toParent parent: Trail?, atIndex index: Int) {
        trail.parentTrail = parent
        trail.orderIndex = Int32(index)
        trail.updatedAt = Date()
        saveContext()
        fetchAllData()
    }
    
    func movePage(_ page: Page, toTrail trail: Trail, atIndex index: Int) {
        page.trail = trail
        page.orderIndex = Int32(index)
        saveContext()
    }
    
    func setActivePage(_ page: Page?) {
        if let currentActive = selectedPage {
            currentActive.isActive = false
        }
        page?.isActive = true
        selectedPage = page
        saveContext()
    }
    
    func toggleTrailCollapsed(_ trail: Trail) {
        trail.isCollapsed.toggle()
        trail.updatedAt = Date()
        saveContext()
    }
    
    func exportTrailsToMarkdown() -> String {
        var markdown = "# Brie Browser Trails\n\n"
        
        for trail in trails {
            markdown += exportTrailToMarkdown(trail, level: 1)
        }
        
        return markdown
    }
    
    private func exportTrailToMarkdown(_ trail: Trail, level: Int) -> String {
        let indent = String(repeating: "  ", count: level - 1)
        var markdown = "\(indent)- \(trail.icon ?? "")[\(trail.name ?? "Untitled")]\n"
        
        if let pages = trail.pages?.array as? [Page] {
            for page in pages {
                markdown += "\(indent)  - [\(page.title ?? "Untitled")](\(page.url?.absoluteString ?? ""))\n"
            }
        }
        
        if let children = trail.childTrails?.array as? [Trail] {
            for child in children {
                markdown += exportTrailToMarkdown(child, level: level + 1)
            }
        }
        
        return markdown
    }
    
    func bulkDelete(_ items: [NSManagedObject]) {
        for item in items {
            context.delete(item)
        }
        saveContext()
        fetchAllData()
    }
    
    func saveContext() {
        CoreDataStack.shared.saveContext()
    }
}

