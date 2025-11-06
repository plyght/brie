import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct TrailRowView: View {
    @ObservedObject var trail: Trail
    @ObservedObject var trailManager: TrailManager
    @State private var showingRenameSheet = false
    @State private var showingIconPicker = false
    @State private var currentNote: Note?
    @Binding var selectedTrail: Trail?
    @Binding var selectedItems: Set<NSManagedObjectID>
    
    var isSelected: Bool {
        selectedTrail?.objectID == trail.objectID
    }
    
    var hasNote: Bool {
        trail.note != nil
    }
    
    var body: some View {
        HStack(spacing: 8) {
            IconView(iconName: trail.icon ?? "folder.fill")
                .frame(width: 16, height: 16)
            
            Text(trail.name ?? "Untitled")
                .font(.system(size: 13))
                .lineLimit(1)
            
            if hasNote {
                Button(action: {
                    currentNote = trail.note
                }) {
                    Image(systemName: "note.text")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Edit Note")
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTrail = trail
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                trailManager.deleteTrail(trail)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                showingRenameSheet = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            
            Button {
                trailManager.createSubTrail(parent: trail)
            } label: {
                Label("New SubTrail", systemImage: "plus")
            }
        }
        .contextMenu {
            Button("Rename") {
                showingRenameSheet = true
            }
            Button("New SubTrail") {
                trailManager.createSubTrail(parent: trail)
            }
            Button("Set Icon") {
                showingIconPicker = true
            }
            if hasNote {
                Button("Edit Note") {
                    currentNote = trail.note
                }
            } else {
                Button("Add Note") {
                    currentNote = trailManager.createNote(trail: trail)
                }
            }
            Divider()
            Button("Delete", role: .destructive) {
                trailManager.deleteTrail(trail)
            }
        }
        .sheet(isPresented: $showingRenameSheet) {
            TrailEditorView(trail: trail, trailManager: trailManager)
        }
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(selectedIcon: Binding(
                get: { trail.icon ?? "folder.fill" },
                set: { newIcon in
                    trailManager.updateTrail(trail, icon: newIcon)
                }
            ))
        }
        .sheet(item: $currentNote) { note in
            NotesEditorView(note: note, trailManager: trailManager)
        }
        .onDrag {
            guard let uri = trail.objectID.uriRepresentation().absoluteString.data(using: .utf8) else {
                return NSItemProvider()
            }
            let provider = NSItemProvider()
            provider.registerDataRepresentation(forTypeIdentifier: UTType.brieTrail.identifier, visibility: .all) { completion in
                completion(uri, nil)
                return nil
            }
            return provider
        }
        .onDrop(of: [UTType.brieTrail], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        let manager = trailManager
        let targetTrailObjectID = trail.objectID
        
        provider.loadDataRepresentation(forTypeIdentifier: UTType.brieTrail.identifier) { data, error in
            guard let data = data,
                  error == nil,
                  let uriString = String(data: data, encoding: .utf8),
                  let uri = URL(string: uriString),
                  let objectID = manager.context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                return
            }
            
            DispatchQueue.main.async {
                do {
                    if let draggedTrail = try manager.context.existingObject(with: objectID) as? Trail,
                       let targetTrail = try manager.context.existingObject(with: targetTrailObjectID) as? Trail,
                       draggedTrail.objectID != targetTrailObjectID {
                        manager.moveTrail(draggedTrail, toParent: targetTrail, atIndex: 0)
                    }
                } catch {
                    print("Error handling drop: \(error)")
                }
            }
        }
        
        return true
    }
}

struct PageRowView: View {
    @ObservedObject var page: Page
    @ObservedObject var trailManager: TrailManager
    @Binding var selectedPage: Page?
    
    var isSelected: Bool {
        selectedPage?.objectID == page.objectID
    }
    
    var body: some View {
        HStack(spacing: 8) {
            IconView(iconName: page.icon ?? "link")
                .frame(width: 16, height: 16)
            
            Text(page.title ?? "Untitled Page")
                .font(.system(size: 12))
                .lineLimit(1)
                .foregroundColor(isSelected ? .primary : .secondary)
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedPage = page
            trailManager.setActivePage(page)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                trailManager.deletePage(page)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
