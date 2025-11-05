import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: IconCategory = .files
    
    enum IconCategory: String, CaseIterable {
        case files = "Files & Folders"
        case work = "Work & Office"
        case tech = "Technology"
        case media = "Media & Entertainment"
        case travel = "Travel"
        case misc = "Miscellaneous"
        
        var icons: [String] {
            switch self {
            case .files:
                return ["folder.fill", "folder", "folder.badge.gearshape", "folder.badge.plus", 
                        "doc.fill", "doc", "doc.text.fill", "doc.on.doc", "archivebox.fill",
                        "tray.fill", "tray", "externaldrive.fill", "folder.badge.person.crop"]
            case .work:
                return ["briefcase.fill", "briefcase", "calendar", "calendar.badge.clock",
                        "clock.fill", "clock", "checkmark.circle.fill", "chart.bar.fill",
                        "chart.line.uptrend.xyaxis", "list.bullet.clipboard.fill", "pencil", "pencil.circle.fill"]
            case .tech:
                return ["desktopcomputer", "laptopcomputer", "display", "keyboard.fill",
                        "server.rack", "cpu", "memorychip", "externaldrive.connected.to.line.below",
                        "network", "antenna.radiowaves.left.and.right", "wifi", "link"]
            case .media:
                return ["play.circle.fill", "music.note", "headphones", "tv.fill",
                        "photo.fill", "camera.fill", "film.fill", "paintbrush.fill",
                        "gamecontroller.fill", "figure.disc.sports", "theatermasks.fill", "mic.fill"]
            case .travel:
                return ["airplane", "car.fill", "bus.fill", "bicycle", 
                        "tram.fill", "ferry.fill", "figure.walk", "location.fill",
                        "map.fill", "globe.americas.fill", "globe", "building.2.fill"]
            case .misc:
                return ["star.fill", "heart.fill", "flame.fill", "lightbulb.fill",
                        "sparkles", "bolt.fill", "flag.fill", "tag.fill",
                        "bell.fill", "gift.fill", "crown.fill", "leaf.fill"]
            }
        }
    }
    
    var filteredIcons: [String] {
        if searchText.isEmpty {
            return selectedCategory.icons
        }
        return selectedCategory.icons.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 8)
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Choose an Icon")
                .font(.headline)
                .padding(.top, 16)
            
            TextField("Search icons...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.top, 12)
            
            Picker("Category", selection: $selectedCategory) {
                ForEach(IconCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredIcons, id: \.self) { iconName in
                        Button(action: {
                            selectedIcon = iconName
                            dismiss()
                        }) {
                            Image(systemName: iconName)
                                .font(.system(size: 24))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == iconName ? Color.accentColor.opacity(0.3) : Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(.bottom, 16)
        }
        .frame(width: 600, height: 500)
    }
}

