import SwiftUI

struct SidebarHeaderView: View {
    @ObservedObject var trailManager: TrailManager
    @State private var showingNewTrailMenu = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text("Trails")
                .font(.headline)
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
                Image(systemName: "plus")
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 20, height: 20)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

