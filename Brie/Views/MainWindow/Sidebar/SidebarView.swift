import SwiftUI
import CoreData

struct SidebarView: View {
    @ObservedObject var trailManager: TrailManager
    @Binding var selectedTrail: Trail?
    @Binding var selectedPage: Page?
    @State private var searchText: String = ""
    @State private var selectedItems: Set<NSManagedObjectID> = []
    
    var filteredAreas: [Area] {
        if searchText.isEmpty {
            return trailManager.areas
        }
        return trailManager.areas.filter { area in
            (area.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (area.trails?.array as? [Trail] ?? []).contains { trail in
                trail.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var filteredFolders: [Folder] {
        if searchText.isEmpty {
            return trailManager.folders
        }
        return trailManager.folders.filter { folder in
            (folder.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (folder.trails?.array as? [Trail] ?? []).contains { trail in
                trail.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var filteredTrails: [Trail] {
        if searchText.isEmpty {
            return trailManager.trails
        }
        return trailManager.trails.filter { trail in
            trail.name?.localizedCaseInsensitiveContains(searchText) ?? false ||
            trailMatchesSearch(trail, searchText: searchText)
        }
    }
    
    func trailMatchesSearch(_ trail: Trail, searchText: String) -> Bool {
        if trail.name?.localizedCaseInsensitiveContains(searchText) ?? false {
            return true
        }
        if let pages = trail.pages?.array as? [Page] {
            if pages.contains(where: { $0.title?.localizedCaseInsensitiveContains(searchText) ?? false }) {
                return true
            }
        }
        if let children = trail.childTrails?.array as? [Trail] {
            return children.contains(where: { trailMatchesSearch($0, searchText: searchText) })
        }
        return false
    }
    
    var body: some View {
        List(selection: Binding(
            get: { 
                if let page = selectedPage {
                    return page.objectID
                }
                return selectedTrail?.objectID
            },
            set: { newValue in
                guard let objectID = newValue else { return }
                if let object = try? trailManager.context.existingObject(with: objectID) {
                    if let trail = object as? Trail {
                        selectedTrail = trail
                        selectedPage = nil
                    } else if let page = object as? Page {
                        selectedPage = page
                        if let trail = page.trail {
                            selectedTrail = trail
                        }
                    }
                }
            }
        )) {
            Section {
                SidebarHeaderView(trailManager: trailManager)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            }
            
            if !filteredAreas.isEmpty {
                Section {
                    ForEach(filteredAreas, id: \.objectID) { area in
                        AreaGroupView(
                            area: area,
                            trailManager: trailManager,
                            selectedTrail: $selectedTrail,
                            selectedPage: $selectedPage,
                            selectedItems: $selectedItems,
                            searchText: searchText
                        )
                    }
                }
            }
            
            if !filteredFolders.isEmpty {
                Section {
                    ForEach(filteredFolders, id: \.objectID) { folder in
                        FolderGroupView(
                            folder: folder,
                            trailManager: trailManager,
                            selectedTrail: $selectedTrail,
                            selectedPage: $selectedPage,
                            selectedItems: $selectedItems,
                            searchText: searchText
                        )
                    }
                }
            }
            
            if !filteredTrails.isEmpty {
                Section {
                    ForEach(filteredTrails, id: \.objectID) { trail in
                        TrailView(
                            trail: trail,
                            trailManager: trailManager,
                            selectedTrail: $selectedTrail,
                            selectedPage: $selectedPage,
                            selectedItems: $selectedItems,
                            searchText: searchText
                        )
                        .tag(trail.objectID)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchText, prompt: "Search trails and pages")
        .environment(\.defaultMinListRowHeight, 28)
        .onReceive(NotificationCenter.default.publisher(for: .createNewTrail)) { _ in
            trailManager.createTrail()
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewSubTrail)) { _ in
            if let selected = selectedTrail {
                trailManager.createSubTrail(parent: selected)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewSideTrail)) { _ in
            if let selected = selectedTrail {
                trailManager.createSideTrail(parent: selected)
            }
        }
    }
}

struct TrailView: View {
    @ObservedObject var trail: Trail
    @ObservedObject var trailManager: TrailManager
    @Binding var selectedTrail: Trail?
    @Binding var selectedPage: Page?
    @Binding var selectedItems: Set<NSManagedObjectID>
    let searchText: String
    
    var sortedPages: [Page] {
        guard let pages = trail.pages?.array as? [Page] else { return [] }
        let sorted = pages.sorted { $0.orderIndex < $1.orderIndex }
        if searchText.isEmpty {
            return sorted
        }
        return sorted.filter { page in
            page.title?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var sortedChildren: [Trail] {
        guard let children = trail.childTrails?.array as? [Trail] else { return [] }
        return children.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: Binding(
            get: { !trail.isCollapsed },
            set: { newValue in
                if trail.isCollapsed == newValue {
                    trailManager.toggleTrailCollapsed(trail)
                }
            }
        )) {
            ForEach(sortedPages, id: \.objectID) { page in
                NavigationLink(value: page.objectID) {
                    PageRowView(
                        page: page,
                        trailManager: trailManager,
                        selectedPage: $selectedPage
                    )
                }
                .listRowBackground(Color.clear)
                .tag(page.objectID)
            }
            
            ForEach(sortedChildren, id: \.objectID) { childTrail in
                TrailView(
                    trail: childTrail,
                    trailManager: trailManager,
                    selectedTrail: $selectedTrail,
                    selectedPage: $selectedPage,
                    selectedItems: $selectedItems,
                    searchText: searchText
                )
            }
        } label: {
            TrailRowView(
                trail: trail,
                trailManager: trailManager,
                selectedTrail: $selectedTrail,
                selectedItems: $selectedItems
            )
            .contentShape(Rectangle())
            .onTapGesture {
                selectedTrail = trail
            }
        }
        .listRowBackground(Color.clear)
        .tag(trail.objectID)
    }
}

struct AreaGroupView: View {
    @ObservedObject var area: Area
    @ObservedObject var trailManager: TrailManager
    @Binding var selectedTrail: Trail?
    @Binding var selectedPage: Page?
    @Binding var selectedItems: Set<NSManagedObjectID>
    let searchText: String
    @State private var isExpanded = true
    
    var sortedTrails: [Trail] {
        guard let trails = area.trails?.array as? [Trail] else { return [] }
        return trails.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(sortedTrails, id: \.objectID) { trail in
                TrailView(
                    trail: trail,
                    trailManager: trailManager,
                    selectedTrail: $selectedTrail,
                    selectedPage: $selectedPage,
                    selectedItems: $selectedItems,
                    searchText: searchText
                )
            }
        } label: {
            HStack(spacing: 8) {
                Text(area.icon ?? "📂")
                    .font(.system(size: 16))
                Text(area.name ?? "Untitled Area")
                    .font(.system(size: 13, weight: .semibold))
            }
        }
        .listRowBackground(Color.clear)
    }
}

struct FolderGroupView: View {
    @ObservedObject var folder: Folder
    @ObservedObject var trailManager: TrailManager
    @Binding var selectedTrail: Trail?
    @Binding var selectedPage: Page?
    @Binding var selectedItems: Set<NSManagedObjectID>
    let searchText: String
    @State private var isExpanded = true
    
    var sortedTrails: [Trail] {
        guard let trails = folder.trails?.array as? [Trail] else { return [] }
        return trails.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(sortedTrails, id: \.objectID) { trail in
                TrailView(
                    trail: trail,
                    trailManager: trailManager,
                    selectedTrail: $selectedTrail,
                    selectedPage: $selectedPage,
                    selectedItems: $selectedItems,
                    searchText: searchText
                )
            }
        } label: {
            HStack(spacing: 8) {
                IconView(iconName: folder.icon ?? "folder")
                    .frame(width: 16, height: 16)
                Text(folder.name ?? "Untitled Folder")
                    .font(.system(size: 13, weight: .semibold))
            }
        }
        .listRowBackground(Color.clear)
    }
}
