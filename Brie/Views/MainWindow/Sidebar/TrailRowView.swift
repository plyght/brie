import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct TrailRowView: View {
    @ObservedObject var trail: Trail
    @ObservedObject var trailManager: TrailManager
    @State private var isHovered = false
    @State private var showingRenameSheet = false
    @State private var showingIconPicker = false
    @State private var showingNoteEditor = false
    @Binding var selectedTrail: Trail?
    @Binding var selectedItems: Set<NSManagedObjectID>
    
    var isSelected: Bool {
        selectedTrail?.objectID == trail.objectID
    }
    
    var hasNote: Bool {
        trail.note != nil
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if let children = trail.childTrails?.array as? [Trail], !children.isEmpty {
                Button(action: {
                    trailManager.toggleTrailCollapsed(trail)
                }) {
                    Image(systemName: trail.isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Spacer()
                    .frame(width: 16)
            }
            
            IconView(iconName: trail.icon ?? "folder.fill")
                .frame(width: 16, height: 16)
            
            Text(trail.name ?? "Untitled")
                .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                .lineLimit(1)
                .foregroundColor(.primary)
            
            if hasNote {
                Image(systemName: "note.text")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isHovered {
                HStack(spacing: 6) {
                    if hasNote {
                        Button(action: {
                            showingNoteEditor = true
                        }) {
                            Image(systemName: "note.text")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button(action: {
                        trailManager.createSubTrail(parent: trail)
                    }) {
                        Image(systemName: "plus")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        showingRenameSheet = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        trailManager.deleteTrail(trail)
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.2) : 
                      (isHovered ? Color.primary.opacity(0.05) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTrail = trail
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
                    showingNoteEditor = true
                }
            } else {
                Button("Add Note") {
                    let note = trailManager.createNote(trail: trail)
                    showingNoteEditor = true
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
        .sheet(isPresented: $showingNoteEditor) {
            if let note = trail.note {
                NotesEditorView(note: note, trailManager: trailManager)
            }
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
        .opacity(isHovered ? 0.9 : 1.0)
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadDataRepresentation(forTypeIdentifier: UTType.brieTrail.identifier) { data, error in
            guard let data = data,
                  error == nil,
                  let uriString = String(data: data, encoding: .utf8),
                  let uri = URL(string: uriString),
                  let objectID = trailManager.context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                return
            }
            
            DispatchQueue.main.async {
                do {
                    if let draggedTrail = try trailManager.context.existingObject(with: objectID) as? Trail,
                       draggedTrail.objectID != trail.objectID {
                        trailManager.moveTrail(draggedTrail, toParent: trail, atIndex: 0)
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
    @State private var isHovered = false
    @Binding var selectedPage: Page?
    
    var isSelected: Bool {
        selectedPage?.objectID == page.objectID
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Spacer()
                .frame(width: 16)
            
            IconView(iconName: page.icon ?? "link")
                .frame(width: 14, height: 14)
                .font(.caption)
            
            Text(page.title ?? "Untitled Page")
                .font(.system(size: 12))
                .lineLimit(1)
                .foregroundColor(isSelected ? .primary : .secondary)
            
            Spacer()
            
            if isHovered {
                Button(action: {
                    trailManager.deletePage(page)
                }) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.leading, 24)
        .padding(.trailing, 8)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : 
                      (isHovered ? Color.primary.opacity(0.04) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedPage = page
            trailManager.setActivePage(page)
        }
    }
}

