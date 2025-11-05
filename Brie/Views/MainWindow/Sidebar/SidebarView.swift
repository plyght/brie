import SwiftUI
import CoreData

struct SidebarView: View {
    @ObservedObject var trailManager: TrailManager
    @Binding var selectedTrail: Trail?
    @Binding var selectedPage: Page?
    @Binding var isCollapsed: Bool
    @State private var selectedItems: Set<NSManagedObjectID> = []
    
    var body: some View {
        VStack(spacing: 0) {
            SidebarHeaderView(trailManager: trailManager, isCollapsed: $isCollapsed)
            
            Divider()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(trailManager.areas, id: \.objectID) { area in
                        AreaGroupView(
                            area: area,
                            trailManager: trailManager,
                            selectedTrail: $selectedTrail,
                            selectedPage: $selectedPage,
                            selectedItems: $selectedItems
                        )
                    }
                    
                    ForEach(trailManager.folders, id: \.objectID) { folder in
                        FolderGroupView(
                            folder: folder,
                            trailManager: trailManager,
                            selectedTrail: $selectedTrail,
                            selectedPage: $selectedPage,
                            selectedItems: $selectedItems
                        )
                    }
                    
                    ForEach(trailManager.trails, id: \.objectID) { trail in
                        TrailView(
                            trail: trail,
                            trailManager: trailManager,
                            selectedTrail: $selectedTrail,
                            selectedPage: $selectedPage,
                            selectedItems: $selectedItems
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
        }
        .frame(minWidth: 200, maxWidth: isCollapsed ? 0 : .infinity)
        .background(.thinMaterial)
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
    
    var sortedPages: [Page] {
        guard let pages = trail.pages?.array as? [Page] else { return [] }
        return pages.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var sortedChildren: [Trail] {
        guard let children = trail.childTrails?.array as? [Trail] else { return [] }
        return children.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TrailRowView(
                trail: trail,
                trailManager: trailManager,
                selectedTrail: $selectedTrail,
                selectedItems: $selectedItems
            )
            
            if !trail.isCollapsed {
                ForEach(sortedPages, id: \.objectID) { page in
                    PageRowView(
                        page: page,
                        trailManager: trailManager,
                        selectedPage: $selectedPage
                    )
                }
                
                ForEach(sortedChildren, id: \.objectID) { childTrail in
                    TrailView(
                        trail: childTrail,
                        trailManager: trailManager,
                        selectedTrail: $selectedTrail,
                        selectedPage: $selectedPage,
                        selectedItems: $selectedItems
                    )
                    .padding(.leading, 20)
                }
            }
        }
    }
}

struct AreaGroupView: View {
    @ObservedObject var area: Area
    @ObservedObject var trailManager: TrailManager
    @Binding var selectedTrail: Trail?
    @Binding var selectedPage: Page?
    @Binding var selectedItems: Set<NSManagedObjectID>
    @State private var isExpanded = true
    
    var sortedTrails: [Trail] {
        guard let trails = area.trails?.array as? [Trail] else { return [] }
        return trails.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                
                Text(area.icon ?? "📂")
                Text(area.name ?? "Untitled Area")
                    .font(.headline)
                
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            
            if isExpanded {
                ForEach(sortedTrails, id: \.objectID) { trail in
                    TrailView(
                        trail: trail,
                        trailManager: trailManager,
                        selectedTrail: $selectedTrail,
                        selectedPage: $selectedPage,
                        selectedItems: $selectedItems
                    )
                    .padding(.leading, 12)
                }
            }
        }
        .padding(.bottom, 8)
    }
}

struct FolderGroupView: View {
    @ObservedObject var folder: Folder
    @ObservedObject var trailManager: TrailManager
    @Binding var selectedTrail: Trail?
    @Binding var selectedPage: Page?
    @Binding var selectedItems: Set<NSManagedObjectID>
    @State private var isExpanded = true
    
    var sortedTrails: [Trail] {
        guard let trails = folder.trails?.array as? [Trail] else { return [] }
        return trails.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                
                IconView(iconName: folder.icon ?? "folder")
                    .frame(width: 16, height: 16)
                Text(folder.name ?? "Untitled Folder")
                    .font(.headline)
                
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            
            if isExpanded {
                ForEach(sortedTrails, id: \.objectID) { trail in
                    TrailView(
                        trail: trail,
                        trailManager: trailManager,
                        selectedTrail: $selectedTrail,
                        selectedPage: $selectedPage,
                        selectedItems: $selectedItems
                    )
                    .padding(.leading, 12)
                }
            }
        }
        .padding(.bottom, 8)
    }
}

