import SwiftUI

struct SidebarToggleButton: View {
    @Binding var isCollapsed: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCollapsed.toggle()
            }
        }) {
            Image(systemName: isCollapsed ? "sidebar.left" : "sidebar.left.fill")
                .font(.system(size: 16))
                .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
        .help(isCollapsed ? "Show Sidebar" : "Hide Sidebar")
        .keyboardShortcut("s", modifiers: [.command, .option])
    }
}

