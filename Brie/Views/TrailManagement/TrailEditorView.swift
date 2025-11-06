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
        VStack(spacing: 24) {
            Text("Edit Trail")
                .font(.headline)
                .padding(.top, 8)
            
            HStack(spacing: 16) {
                Button(action: { showingIconPicker.toggle() }) {
                    IconView(iconName: selectedIcon)
                        .font(.system(size: 40))
                        .frame(width: 80, height: 80)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help("Change Icon")
                
                TextField("Trail Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
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
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 450, height: 250)
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(selectedIcon: $selectedIcon)
        }
    }
}

