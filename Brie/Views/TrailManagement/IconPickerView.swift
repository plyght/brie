import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) var dismiss
    
    let commonEmojis = [
        "📁", "📂", "🗂️", "📋", "📄", "📃", "📑", "🗃️",
        "💼", "📚", "📖", "📕", "📗", "📘", "📙",
        "🏠", "🏢", "🏫", "🏪", "🏭", "🏗️",
        "💻", "⌨️", "🖥️", "🖨️", "🖱️", "💾",
        "🌐", "🔍", "🔎", "🔖", "📌", "📍",
        "⭐", "🌟", "✨", "💫", "🔥", "💡",
        "❤️", "💚", "💙", "💜", "🧡", "💛",
        "🎨", "🎭", "🎪", "🎬", "🎮", "🎯",
        "🚀", "✈️", "🚁", "🚂", "🚗", "🚕",
        "🎵", "🎶", "🎼", "🎤", "🎧", "📻",
        "📱", "📞", "☎️", "📠", "📡", "📢"
    ]
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 8)
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Choose an Icon")
                .font(.headline)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(commonEmojis, id: \.self) { emoji in
                        Button(action: {
                            selectedIcon = emoji
                            dismiss()
                        }) {
                            Text(emoji)
                                .font(.system(size: 30))
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == emoji ? Color.accentColor.opacity(0.3) : Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

