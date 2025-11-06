import SwiftUI
import CoreData

struct NotesEditorView: View {
    @ObservedObject var note: Note
    @ObservedObject var trailManager: TrailManager
    @State private var content: String
    @Environment(\.dismiss) var dismiss
    
    init(note: Note, trailManager: TrailManager) {
        self.note = note
        self.trailManager = trailManager
        _content = State(initialValue: note.content ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                IconView(iconName: note.trail?.icon ?? "note.text")
                    .frame(width: 24, height: 24)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.trail?.name ?? "Note")
                        .font(.headline)
                    if let updatedAt = note.updatedAt {
                        Text("Last edited: \(updatedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            TextEditor(text: $content)
                .font(.body)
                .padding(16)
                .onChange(of: content) { _, newValue in
                    note.content = newValue
                    note.updatedAt = Date()
                    trailManager.saveContext()
                }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

