import SwiftUI

struct SidebarHeaderView: View {
    @ObservedObject var trailManager: TrailManager
    @Binding var isCollapsed: Bool
    @State private var showingNewTrailMenu = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text("Trails")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            SidebarToggleButton(isCollapsed: $isCollapsed)
            
            Menu {
                Button("New Trail") {
                    trailManager.createTrail()
                }
                Button("New Area") {
                    trailManager.createArea(name: "New Area")
                }
                Button("New Folder") {
                    trailManager.createFolder(name: "New Folder")
                }
                Button("New Note") {
                    let trail = trailManager.createTrail(type: .note)
                    trailManager.createNote(trail: trail)
                }
            } label: {
                Image(systemName: "plus")
                    .font(.body)
                    .foregroundColor(.primary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

