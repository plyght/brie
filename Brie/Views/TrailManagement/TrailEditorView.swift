import SwiftUI
import CoreData

struct TrailEditorView: View {
    @ObservedObject var trail: Trail
    @ObservedObject var trailManager: TrailManager
    @State private var name: String
    @State private var selectedIcon: String
    @State private var showingIconPicker = false
    @Environment(\.dismiss) var dismiss
    
    init(trail: Trail, trailManager: TrailManager) {
        self.trail = trail
        self.trailManager = trailManager
        _name = State(initialValue: trail.name ?? "")
        _selectedIcon = State(initialValue: trail.icon ?? "📁")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Trail")
                .font(.headline)
            
            HStack {
                Button(action: { showingIconPicker.toggle() }) {
                    Text(selectedIcon)
                        .font(.system(size: 40))
                        .frame(width: 60, height: 60)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                TextField("Trail Name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    trailManager.updateTrail(trail, name: name, icon: selectedIcon)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400)
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(selectedIcon: $selectedIcon)
        }
    }
}

