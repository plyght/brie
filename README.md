# Brie

A native macOS browser built with WebKit and SwiftUI, featuring hierarchical navigation through Trails.

## Overview

Brie reimagines web browsing with **Trails** - a hierarchical navigation system that replaces traditional tabs. Organize your browsing into nested structures, making it easier to track research, manage multiple projects, and stay productive.

## Features

### Core Features

- **Trails System**: Hierarchical sidebar navigation that captures your browsing journey
- **SubTrails**: Nested children of parent Trails for detailed organization
- **SideTrails**: Separate but connected lines of research
- **Areas & Folders**: Group related Trails by project, topic, or context
- **Notes**: Built-in note-taking directly within Trails
- **Collapsible Sidebar**: Toggle visibility for focused browsing
- **Persistent Storage**: All Trails, Pages, and Notes are automatically saved

### Customization

- **Custom Icons**: Assign emojis or icons to Trails and Pages
- **Drag & Drop**: Reorganize Trails and Pages with intuitive drag-and-drop
- **Rename Anything**: Customize names for better organization
- **Search Engines**: Choose from Google, Bing, DuckDuckGo, Kagi, or Brave

### Keyboard Shortcuts

- **⌘T**: New Trail
- **⌥⌘T**: New SubTrail
- **⌥⇧⌘T**: New SideTrail
- **⌘W**: Close Trail/Page
- **⇧⌘L**: Rename Trail
- **⌥⌘S**: Toggle Sidebar
- **⌘,**: Settings

## Technical Stack

- **Platform**: macOS 14.0+ (optimized for macOS 26 Tahoe)
- **UI Framework**: SwiftUI with native macOS components
- **Browser Engine**: WebKit (WKWebView)
- **Data Persistence**: Core Data
- **Language**: Swift 6.0

## Architecture

```
Brie/
├── App/                    # Application entry point and lifecycle
├── Core/                   # Core Data models and business logic
│   ├── Models/            # Trail, Page, Area, Folder, Note entities
│   ├── CoreDataStack.swift
│   └── TrailManager.swift
├── Views/                  # SwiftUI views
│   ├── MainWindow/        # Main window with sidebar and browser
│   ├── TrailManagement/   # Trail editing, icons, notes
│   └── Settings/          # Settings and preferences
├── Services/               # Business logic services
│   ├── WebViewService.swift
│   ├── SearchEngineService.swift
│   ├── KeyboardShortcutsService.swift
│   └── PersistenceService.swift
└── Utilities/              # Helper functions and extensions
```

## Building

### Prerequisites

- Xcode 17.0+
- macOS 14.0+ SDK
- Swift 6.0+

### Build Instructions

1. Open `Brie.xcodeproj` in Xcode
2. Select the Brie scheme
3. Build and run (⌘R)

## Core Data Model

### Entities

- **Trail**: Core navigation unit with hierarchical relationships
- **Page**: Web page within a Trail
- **Area**: Container for organizing groups of Trails
- **Folder**: File system-like organization
- **Note**: Text notes associated with Trails

### Relationships

- Trails can have parent Trails (for SubTrails)
- Trails can contain multiple Pages
- Areas and Folders can contain multiple Trails
- Notes are one-to-one with Trails

## Usage

### Creating Trails

1. Click the **+** button in the sidebar header
2. Or use **⌘T** keyboard shortcut
3. Navigate to a URL - it will automatically be added to the current Trail

### Organizing with SubTrails

1. Hover over a Trail and click the **+** icon
2. Or select a Trail and press **⌥⌘T**
3. The new SubTrail will be nested under the parent

### Areas and Folders

1. Click the Area or Folder icon in the sidebar header
2. Give it a name
3. Drag Trails into the Area or Folder to organize

### Notes

1. Click the Note icon in the sidebar header
2. Start typing your notes
3. Notes are saved automatically as you type

## Data Management

### Export

- Export all Trails to Markdown via Settings → Advanced → Export Trails
- Preserves hierarchical structure and links

### Backup

- Core Data store is automatically backed up
- Located at: `~/Library/Application Support/Brie/`

## Roadmap

- [ ] iCloud sync for Trails across devices
- [ ] Tab Groups import from Safari
- [ ] Advanced search within Trails
- [ ] Trail sharing and collaboration
- [ ] Browser extensions support
- [ ] Reading mode integration
- [ ] Spotlight integration for quick Trail access

## License

Copyright © 2025. All rights reserved.

## Development

Built with production-grade patterns:
- Clean architecture with separation of concerns
- Observable pattern for reactive UI updates
- Core Data for robust persistence
- Native macOS design patterns

---

**Brie** - Browse naturally, organize effortlessly.

