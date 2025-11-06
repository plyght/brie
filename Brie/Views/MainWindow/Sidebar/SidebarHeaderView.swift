import SwiftUI

struct SidebarHeaderView: View {
    @ObservedObject var trailManager: TrailManager
    @State private var showingNewTrailMenu = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text("Trails")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
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
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)
                    .symbolRenderingMode(.hierarchical)
            }
            .menuStyle(.borderlessButton)
            .help("Add New Item")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

