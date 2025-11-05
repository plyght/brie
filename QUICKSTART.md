# Brie Browser - Quick Start Guide

## Opening the Project

```bash
cd /Users/nicojaffer/brie
open Brie.xcodeproj
```

## First Run

1. **Open in Xcode** (Xcode 17.0+)
2. **Select Target**: Brie (macOS)
3. **Press ⌘R** to build and run

The app will launch with a welcome Trail and open Google's homepage.

## Basic Usage

### Creating Your First Trail
- Click the **+** button in the sidebar
- Or press **⌘T**
- Enter a URL or search query in the address bar
- The page automatically adds to the current Trail

### Organizing with SubTrails
- Hover over a Trail
- Click the **+** icon that appears
- Or press **⌥⌘T** with a Trail selected

### Using Areas and Folders
- Click the **Area** or **Folder** icon in sidebar header
- Name your container
- Drag Trails into it to organize

### Notes
- Click the **Note** icon in sidebar header
- Start typing
- Notes auto-save as you type

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| New Trail | ⌘T |
| New SubTrail | ⌥⌘T |
| New SideTrail | ⌥⇧⌘T |
| Close Trail/Page | ⌘W |
| Rename Trail | ⇧⌘L |
| Toggle Sidebar | ⌥⌘S |
| Settings | ⌘, |

## Project Structure

```
Brie/
├── App/              → App lifecycle
├── Core/             → Data models & business logic
├── Views/            → SwiftUI views
├── Services/         → Business services
├── Utilities/        → Helpers & extensions
└── Resources/        → Assets & Core Data model
```

## Key Files

- **BrieApp.swift**: Main app entry point
- **MainWindowView.swift**: Main UI with sidebar + browser
- **TrailManager.swift**: All Trail operations (CRUD)
- **WebViewService.swift**: Browser functionality
- **CoreDataStack.swift**: Data persistence

## Core Data Model

The app uses Core Data with 5 entities:
- **Trail**: Core navigation unit (hierarchical)
- **Page**: Web pages within Trails
- **Area**: Organizational container
- **Folder**: File-like container
- **Note**: Text notes

## Customizing

### Changing Default Search Engine
1. Open Settings (⌘,)
2. General tab
3. Select search engine from dropdown

### Modifying Keyboard Shortcuts
Edit `Constants.swift` to change default shortcuts.

## Debugging

### View Core Data Storage
```swift
print(NSPersistentContainer.defaultDirectoryURL())
```
Located at: `~/Library/Application Support/Brie/`

### Reset All Data
Settings → Advanced → Clear All Data

### Export Trails
Settings → Advanced → Export Trails to Markdown

## Common Development Tasks

### Adding a New Feature
1. Create view in `Views/`
2. Add business logic to `TrailManager.swift` or create new service
3. Update Core Data model if needed (don't forget to create new version)
4. Wire up keyboard shortcuts in `KeyboardShortcutsService.swift`

### Modifying Core Data
1. Open `Brie.xcdatamodeld`
2. Editor → Add Model Version
3. Make changes
4. Set as current version
5. Add migration if needed

### Adding a Search Engine
Edit `SearchEngines` struct in `Constants.swift`:
```swift
static let myEngine = SearchEngine(
    name: "My Engine",
    urlTemplate: "https://example.com/search?q=%@"
)
```

## Building for Distribution

### Debug Build
```bash
xcodebuild -project Brie.xcodeproj -scheme Brie -configuration Debug
```

### Release Build
```bash
xcodebuild -project Brie.xcodeproj -scheme Brie -configuration Release
```

### Archive
1. Product → Archive
2. Organizer → Distribute App
3. Choose distribution method

## Troubleshooting

### Build Errors
- Clean build folder: ⌘⇧K
- Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Restart Xcode

### WebView Not Loading
- Check network connection
- Verify URL scheme (http/https)
- Check Console for WKWebView errors

### Core Data Errors
- Delete app from Applications
- Remove data: `~/Library/Application Support/Brie/`
- Rebuild and run

### Sidebar Not Showing
- Press ⌥⌘S to toggle
- Check `isSidebarCollapsed` state in `MainWindowView`

## Testing Tips

1. **Test Trail Hierarchy**: Create nested SubTrails 5+ levels deep
2. **Test Persistence**: Quit app, relaunch, verify Trails restored
3. **Test Drag & Drop**: Move Trails between Areas/Folders
4. **Test Large Data**: Create 100+ Trails, verify performance
5. **Test WebView**: Load various websites, check memory usage

## Performance Optimization

### WebView Memory
- Only one WebView is instantiated per window
- Old page snapshots are stored as Data (not live WebViews)
- Clear snapshots for very old pages if needed

### Core Data
- Fetch requests use predicates for efficiency
- Ordered relationships maintain Trail hierarchy
- Background contexts for heavy operations

### UI Responsiveness
- All animations use `.easeInOut` for smooth transitions
- Sidebar uses `LazyVStack` for efficient rendering
- Only visible Trails are rendered (collapsed Trails' children are hidden)

## Next Steps

1. **Run the app** and create some Trails
2. **Explore the code** starting with `MainWindowView.swift`
3. **Check the plan** in `macos-trails-browser.plan.md`
4. **Read implementation details** in `IMPLEMENTATION_SUMMARY.md`
5. **Customize** to your needs!

## Support

For issues or questions:
1. Check `IMPLEMENTATION_SUMMARY.md` for known limitations
2. Review Core Data model in Xcode
3. Enable debug logging in `TrailManager.swift`
4. Check Console app for runtime logs

---

**Happy browsing with Trails! 🧀**

