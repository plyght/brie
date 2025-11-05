import SwiftUI
import CoreData

struct NotesEditorView: View {
    @ObservedObject var note: Note
    @ObservedObject var trailManager: TrailManager
    @State private var content: String
    
    init(note: Note, trailManager: TrailManager) {
        self.note = note
        self.trailManager = trailManager
        _content = State(initialValue: note.content ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(note.trail?.icon ?? "📝")
                    .font(.title2)
                Text(note.trail?.name ?? "Note")
                    .font(.headline)
                Spacer()
                Text("Last edited: \(note.updatedAt?.formatted() ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            TextEditor(text: $content)
                .font(.body)
                .padding()
                .onChange(of: content) { _, newValue in
                    note.content = newValue
                    note.updatedAt = Date()
                    trailManager.saveContext()
                }
        }
    }
}

