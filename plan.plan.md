<!-- 43feb900-347a-4862-ba17-4f607a645f52 7ca375b1-11e9-4844-b8d4-452197f68137 -->
# Brie Browser - Fixes & Improvements Plan

## Overview

This plan addresses 20 identified issues and improvements needed in the Brie Browser codebase. Issues are organized by priority and implementation phase, building on the completed initial implementation.

## Phase 1: Critical Fixes

### Issue 1: SearchEngine Codable/Identifiable Conflict
**Priority**: Critical  
**Files**: `Brie/Utilities/Constants.swift`, `Brie/Services/SearchEngineService.swift`

**Problem**: `SearchEngine` struct has `let id = UUID()` which creates a new UUID on every instance, making UserDefaults persistence fail. `Codable` and `Identifiable` conflict when comparing/searching.

**Solution**:
- Make `id` a computed property based on `name` or exclude it from Codable
- Use `name` as the primary identifier for equality/hashing
- Store search engine by name (String) in UserDefaults instead of full object
- Update `SearchEngineService` to load/search by name

**Implementation**:
1. Modify `SearchEngine` struct to make `id` computed or remove from Codable
2. Implement `Equatable` and `Hashable` using `name`
3. Update `SearchEngineService` to store/load by name string
4. Test persistence across app restarts

---

### Issue 2: Missing Core Data Imports
**Priority**: Critical  
**Files**: 
- `Brie/Views/MainWindow/Sidebar/TrailRowView.swift`
- `Brie/Views/MainWindow/Sidebar/SidebarView.swift`
- `Brie/Views/MainWindow/MainWindowView.swift`
- `Brie/Views/TrailManagement/TrailEditorView.swift`
- `Brie/Views/TrailManagement/NotesEditorView.swift`

**Problem**: Files using Core Data entities don't explicitly import CoreData, relying on implicit imports which may fail.

**Solution**: Add `import CoreData` to all files that use NSManagedObject subclasses.

**Implementation**:
1. Add `import CoreData` to each listed file
2. Verify compilation succeeds
3. Test that Core Data entities are accessible

---

### Issue 7: WebViewService Combine Cancellables Not Stored
**Priority**: Critical  
**Files**: `Brie/Services/WebViewService.swift`

**Problem**: `WebViewService` creates Combine publishers but doesn't store cancellables properly, potentially causing memory leaks or lost subscriptions.

**Solution**:
- Store cancellables in `Set<AnyCancellable>`
- Properly cancel on deinit
- Handle webView deallocation

**Implementation**:
1. Store all Combine subscriptions in `observations` Set
2. Cancel all subscriptions in `deinit`
3. Handle webView becoming nil
4. Test for memory leaks

---

### Issue 12: Missing Error Handling
**Priority**: Critical  
**Files**: `Brie/Core/TrailManager.swift`, `Brie/Core/CoreDataStack.swift`

**Problem**: Core Data operations lack proper error handling - many `try?` usages that silently fail.

**Solution**:
- Add proper error handling with user-facing messages
- Log errors appropriately
- Show alerts for critical failures
- Handle Core Data concurrency errors

**Implementation**:
1. Replace `try?` with proper `do-catch` blocks
2. Create error alert system
3. Add logging for debugging
4. Handle context save errors gracefully
5. Show user-friendly error messages

---

## Phase 2: Core Functionality Fixes

### Issue 3: Drag & Drop Implementation Issues
**Priority**: High  
**Files**: `Brie/Views/MainWindow/Sidebar/TrailRowView.swift`

**Problem**: Drag and drop uses fragile URL-based object ID reconstruction. The `onDrop` handler tries to decode object IDs from URIs, which may fail.

**Solution**:
- Use proper drag data type (custom UniformTypeIdentifier)
- Store NSManagedObjectID as data, not URI string
- Improve error handling in drop handler
- Add visual feedback during drag

**Implementation**:
1. Define custom UTType for Trail drag data
2. Store NSManagedObjectID as archived data
3. Improve drop handler with proper error handling
4. Add visual drag feedback (opacity, highlight)
5. Test drag & drop across different scenarios

---

### Issue 4: Missing Sort Descriptors for Display
**Priority**: High  
**Files**: `Brie/Views/MainWindow/Sidebar/SidebarView.swift`, `Brie/Core/TrailManager.swift`

**Problem**: Pages and child Trails aren't sorted by `orderIndex` when displayed, causing inconsistent ordering.

**Solution**:
- Sort pages by orderIndex before displaying
- Sort childTrails by orderIndex before displaying
- Ensure orderIndex is maintained on reorder operations

**Implementation**:
1. Add sorting helper functions in TrailManager
2. Sort pages array before ForEach in TrailView
3. Sort childTrails array before ForEach in TrailView
4. Verify orderIndex updates on move operations
5. Test with multiple items

---

### Issue 8: Notes Feature Incomplete
**Priority**: High  
**Files**: `Brie/Views/MainWindow/Sidebar/TrailRowView.swift`, `Brie/Views/MainWindow/Sidebar/SidebarView.swift`, `Brie/Views/TrailManagement/NotesEditorView.swift`

**Problem**: `NotesEditorView` exists but there's no way to view/edit notes from the sidebar. Notes aren't displayed as rows in TrailView.

**Solution**:
- Add `NoteRowView` component
- Display notes in TrailView when trail has a note
- Add button to create/edit note from TrailRowView
- Show note indicator in TrailRowView

**Implementation**:
1. Create `NoteRowView` component similar to `PageRowView`
2. Add note display in `TrailView` after pages
3. Add "Edit Note" button to TrailRowView hover menu
4. Add note indicator icon in TrailRowView
5. Wire up NotesEditorView sheet
6. Test note creation and editing

---

### Issue 14: Missing Link Click Handling
**Priority**: High  
**Files**: `Brie/Services/WebViewService.swift`, `Brie/Views/MainWindow/MainWindowView.swift`

**Problem**: When clicking links in WebView, they should create new Pages in the current Trail, but this isn't properly implemented.

**Solution**:
- Implement WKNavigationDelegate to intercept link clicks
- Create new Page when user clicks link
- Update TrailManager accordingly

**Implementation**:
1. Add navigation action callback to WebViewService
2. Intercept link clicks in `decidePolicyFor navigationAction`
3. Create Page in current Trail when link clicked
4. Update MainWindowView to handle new pages
5. Test with various link types

---

### Issue 19: Page Title Updates Not Reflected
**Priority**: High  
**Files**: `Brie/Views/MainWindow/MainWindowView.swift`, `Brie/Views/MainWindow/Sidebar/TrailRowView.swift`

**Problem**: When WebView finishes loading, page title updates don't always reflect in the sidebar.

**Solution**:
- Ensure PageRowView observes Page changes
- Update Page title when WebView title changes
- Refresh sidebar when needed

**Implementation**:
1. Ensure Page updates trigger UI refresh
2. Update Page title in WebViewService delegate
3. Save Page updates to Core Data
4. Verify sidebar updates automatically
5. Test with slow-loading pages

---

## Phase 3: UI Improvements

### Issue 5: Unused SidebarToggleButton
**Priority**: Medium  
**Files**: `Brie/Views/MainWindow/MainWindowView.swift`, `Brie/Views/MainWindow/Sidebar/SidebarHeaderView.swift`

**Problem**: `SidebarToggleButton.swift` is created but never integrated into the UI.

**Solution**:
- Add toggle button to MainWindowView or SidebarHeaderView
- Connect it to the sidebar collapse state

**Implementation**:
1. Add SidebarToggleButton to SidebarHeaderView
2. Bind to isSidebarCollapsed state
3. Test toggle functionality
4. Ensure keyboard shortcut works

---

### Issue 6: KeyboardShortcutsService Not Integrated
**Priority**: Medium  
**Files**: `Brie/App/BrieApp.swift`, `Brie/App/AppDelegate.swift`, `Brie/Services/KeyboardShortcutsService.swift`

**Problem**: `KeyboardShortcutsService` is created but never initialized or used. Shortcuts are handled directly in `BrieApp.swift`.

**Solution**:
- Initialize service in `BrieApp` or `AppDelegate`
- Remove duplicate shortcut handling
- Use service as single source of truth for shortcuts

**Implementation**:
1. Initialize KeyboardShortcutsService.shared in AppDelegate
2. Remove duplicate shortcuts from BrieApp commands
3. Route all shortcuts through service
4. Test all shortcuts work correctly

---

### Issue 9: Empty "Set Icon" Context Menu Action
**Priority**: Medium  
**Files**: `Brie/Views/MainWindow/Sidebar/TrailRowView.swift`

**Problem**: In `TrailRowView` context menu, "Set Icon" button has empty action.

**Solution**:
- Connect to icon picker sheet
- Show IconPickerView when clicked

**Implementation**:
1. Add state variable for showing icon picker
2. Wire up "Set Icon" button action
3. Show IconPickerView sheet
4. Update trail icon on selection
5. Test icon selection

---

### Issue 11: Missing Validation
**Priority**: Medium  
**Files**: `Brie/Core/TrailManager.swift`, `Brie/Views/TrailManagement/TrailEditorView.swift`, `Brie/Views/MainWindow/Content/BrowserAddressBar.swift`

**Problem**: No validation for empty Trail names, invalid URLs, duplicate Trails, etc.

**Solution**:
- Validate Trail names (non-empty, reasonable length)
- Validate URLs before creating Pages
- Prevent duplicate Trail names in same parent
- Show error messages to user

**Implementation**:
1. Add validation functions to TrailManager
2. Validate Trail names (1-100 chars)
3. Validate URLs before creating Pages
4. Check for duplicate names in same parent
5. Show error alerts for validation failures
6. Test edge cases

---

### Issue 13: Browser Address Bar URL Display
**Priority**: Medium  
**Files**: `Brie/Views/MainWindow/Content/BrowserAddressBar.swift`, `Brie/Services/WebViewService.swift`

**Problem**: Address bar doesn't update correctly when navigating via links. The `onChange` might fire before URL is ready.

**Solution**:
- Improve URL sync between WebView and address bar
- Handle navigation events properly
- Show loading state in address bar

**Implementation**:
1. Update address bar in WebViewService delegate methods
2. Handle loading states properly
3. Show loading indicator in address bar
4. Test URL synchronization
5. Test navigation via links

---

### Issue 15: Incomplete Settings Implementation
**Priority**: Medium  
**Files**: `Brie/Views/Settings/SettingsView.swift`, `Brie/Services/PersistenceService.swift`

**Problem**: Settings view has placeholder buttons ("Clear All Data", "Clear Cache") with empty actions.

**Solution**:
- Implement clear all data functionality with confirmation
- Implement cache clearing
- Add proper error handling

**Implementation**:
1. Add confirmation dialog for clear all data
2. Implement clearAllData in PersistenceService
3. Add cache clearing functionality
4. Show success/error messages
5. Test data clearing and recovery

---

### Issue 10: SideTrail Logic Issue
**Priority**: Medium  
**Files**: `Brie/Core/TrailManager.swift`, `Brie/Views/MainWindow/Sidebar/SidebarView.swift`

**Problem**: `createSideTrail` sets `parentTrail`, which contradicts the "separate but connected" concept. SideTrails should be siblings, not children.

**Solution**:
- Reconsider SideTrail model - should they be at same level as parent?
- Or create separate relationship type
- Update display logic to show SideTrails correctly

**Implementation**:
1. Review SideTrail requirements from spec
2. Decide on data model (sibling vs separate relationship)
3. Update createSideTrail logic
4. Update display logic in SidebarView
5. Test SideTrail creation and display

---

## Phase 4: Polish & Enhancements

### Issue 16: Missing Multi-Select Functionality
**Priority**: Low  
**Files**: `Brie/Views/MainWindow/Sidebar/SidebarView.swift`, `Brie/Views/MainWindow/Sidebar/TrailRowView.swift`

**Problem**: Bulk operations are mentioned but multi-select (⌘+Click) isn't properly implemented in sidebar.

**Solution**:
- Implement proper multi-select state management
- Add visual feedback for selected items
- Implement bulk delete/move/export actions
- Add selection menu

**Implementation**:
1. Add multi-select state to SidebarView
2. Handle ⌘+Click for multi-select
3. Add visual selection indicators
4. Implement bulk actions menu
5. Add bulk delete/move/export functions
6. Test multi-select operations

---

### Issue 17: Collapse/Expand Trail Keyboard Shortcuts
**Priority**: Low  
**Files**: `Brie/Services/KeyboardShortcutsService.swift`, `Brie/Views/MainWindow/MainWindowView.swift`

**Problem**: Keyboard shortcuts for collapse/expand (⌘⇧◀︎/▶︎) aren't implemented.

**Solution**:
- Add keyboard shortcut handling
- Implement collapse/expand for selected Trail
- Add to KeyboardShortcutsService

**Implementation**:
1. Add collapse/expand shortcuts to KeyboardShortcutsService
2. Handle arrow key shortcuts
3. Implement collapse/expand for selected Trail
4. Test keyboard shortcuts

---

### Issue 18: Missing Favicon Support
**Priority**: Low  
**Files**: `Brie/Services/WebViewService.swift`, `Brie/Views/MainWindow/Sidebar/TrailRowView.swift`

**Problem**: Page icons aren't automatically fetched from websites.

**Solution**:
- Implement favicon fetching from WebView
- Store favicon URLs or images
- Display favicons in PageRowView

**Implementation**:
1. Extract favicon URL from WebView
2. Store favicon URL in Page entity
3. Load and display favicons in PageRowView
4. Add fallback icon
5. Test with various websites

---

### Issue 20: Missing Animation Improvements
**Priority**: Low  
**Files**: Various view files

**Problem**: Some animations are missing or could be smoother.

**Solution**:
- Add smooth transitions for sidebar collapse/expand
- Animate Trail collapse/expand
- Add loading animations for WebView
- Improve drag feedback

**Implementation**:
1. Add animation to sidebar collapse/expand
2. Animate Trail expand/collapse
3. Add WebView loading animation
4. Improve drag visual feedback
5. Test all animations

---

## Implementation Summary

### Phase 1: Critical Fixes (Estimated: 2-3 hours)
- [ ] Issue 1: SearchEngine Codable fix
- [ ] Issue 2: Add Core Data imports
- [ ] Issue 7: Fix WebViewService cancellables
- [ ] Issue 12: Add error handling

### Phase 2: Core Functionality (Estimated: 4-6 hours)
- [ ] Issue 3: Improve drag & drop
- [ ] Issue 4: Add sort descriptors
- [ ] Issue 8: Complete notes feature
- [ ] Issue 14: Implement link click handling
- [ ] Issue 19: Fix page title updates

### Phase 3: UI Improvements (Estimated: 6-8 hours)
- [ ] Issue 5: Integrate sidebar toggle button
- [ ] Issue 6: Integrate KeyboardShortcutsService
- [ ] Issue 9: Fix Set Icon action
- [ ] Issue 10: Fix SideTrail logic
- [ ] Issue 11: Add validation
- [ ] Issue 13: Improve address bar
- [ ] Issue 15: Complete settings

### Phase 4: Polish (Estimated: 4-6 hours)
- [ ] Issue 16: Multi-select functionality
- [ ] Issue 17: Collapse/expand shortcuts
- [ ] Issue 18: Favicon support
- [ ] Issue 20: Animation improvements

**Total Estimated Time: 16-23 hours**

---

## Testing Checklist

After each phase:
- [ ] Build succeeds without errors
- [ ] App launches successfully
- [ ] Core functionality works
- [ ] No memory leaks (Instruments)
- [ ] UI is responsive
- [ ] Data persists correctly

---

## Notes

- Fixes should be implemented incrementally, testing after each major change
- Critical fixes should be done first as they may cause runtime failures
- UI improvements can be done in parallel where possible
- Consider creating unit tests for Core Data operations
- Document any architectural decisions made during fixes


