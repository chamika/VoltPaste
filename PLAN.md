# VoltPaste - Implementation Plan

## Overview
VoltPaste is a macOS clipboard history manager (similar to PasteNow). It runs in the background, monitors clipboard changes, and provides a Spotlight-like popup for browsing and pasting from clipboard history.

---

## Compatibility
- **Minimum deployment target**: macOS 15.0 (Sequoia)
- **Swift**: 6.0 (strict concurrency enabled)
- **Supported**: macOS 15 Sequoia, macOS 26+

## Architecture

### Tech Stack
- **UI**: SwiftUI (latest macOS 15 APIs)
- **Data Persistence**: SwiftData (`@Model`) with macOS 15 enhancements (compound `#Predicate`, `@Attribute` options)
- **State Management**: `@Observable` macro, `@Bindable`, `@Entry` for custom environment values
- **Concurrency**: Swift 6 strict concurrency — `@MainActor`, `Sendable`, structured concurrency
- **Clipboard Monitoring**: `NSPasteboard` polling via `Timer` (every 0.5s)
- **Global Hotkeys**: Carbon `RegisterEventHotKey` API (requires Accessibility permission)
- **Popup Window**: `NSPanel` (floating, key-window capable) wrapped for SwiftUI
- **Menu Bar**: SwiftUI `MenuBarExtra`
- **App Sandbox**: Enabled (kept for potential App Store distribution)

### App Lifecycle
- App launches as a **menu bar agent** (`LSUIElement = true`) — no Dock icon, no main window
- A `MenuBarExtra` provides the tray icon
- Clipboard polling starts immediately on launch
- Global hotkey listener registers after Accessibility permission is granted

---

## Data Model

### ClipboardItem (SwiftData @Model)
| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Unique identifier |
| `content` | `Data` | Full clipboard data for pasting (`@Attribute(.externalStorage)`) |
| `contentType` | `String` | Enum-backed: `text`, `image`, `url`, `file`, `code` |
| `textPreview` | `String?` | First ~200 chars for text items, filename for files |
| `thumbnailData` | `Data?` | Thumbnail image (max 200x200) for image items |
| `sourceAppBundleID` | `String?` | Which app the copy came from |
| `sourceAppName` | `String?` | Human-readable app name |
| `timestamp` | `Date` | When the item was copied |
| `isPinned` | `Bool` | Whether item is pinned (won't auto-delete) |
| `contentHash` | `String` | SHA256 hash to detect duplicates |

Use `@Attribute(.externalStorage)` on `content` and `thumbnailData` to keep large blobs out of the SQLite database.

SwiftData queries will use `#Predicate` with compound filters for search + content type filtering.

### UserSettings (stored via `@AppStorage` / `UserDefaults`)
| Setting | Default |
|---------|---------|
| `maxHistoryItems` | `500` |
| `startAtLogin` | `false` |
| `soundEnabled` | `true` |
| `soundInFocusMode` | `false` |
| `pasteShortcut` | `Cmd + Shift + V` |
| `pasteOriginalTextShortcut` | `Cmd + Option + V` |

---

## Features & Implementation

### 1. Clipboard Monitoring
- **Timer-based polling** of `NSPasteboard.general` every 0.5 seconds
- Compare `changeCount` to detect new copies
- Extract content type from pasteboard types (`NSPasteboardTypeString`, `NSPasteboardTypePNG`, `NSPasteboardTypeURL`, etc.)
- Detect content type:
  - **URL**: Check for `public.url` type or text matching URL pattern
  - **Image**: Check for `public.png`, `public.tiff`, `public.jpeg`
  - **File**: Check for `public.file-url`
  - **Code**: Heuristic — text with common code patterns (braces, semicolons, indentation) or copied from known IDEs (Xcode, VS Code)
  - **Text**: Default fallback
- Generate SHA256 hash to skip duplicates (move existing duplicate to top instead)
- Generate thumbnail for images (resize to max 200x200 preserving aspect ratio)
- Enforce `maxHistoryItems` limit — delete oldest unpinned items when exceeded
- Play sound effect on new item capture (if enabled, respecting Focus mode)
- Service class is `@Observable` and `@MainActor` isolated for safe UI updates

### 2. Popup Window (Spotlight-like)
- **NSPanel subclass** configured as:
  - `.nonactivatingPanel` style (doesn't steal focus from other apps)
  - Floating level, centered on screen
  - Rounded corners, shadow, vibrancy (`.behindWindow` material)
  - Dismisses on `Escape` key or clicking outside
- **Layout** (top to bottom):
  - Search bar (magnifying glass icon + text field, auto-focused)
  - Content type filter chips: All | Text | Images | URLs | Files | Code
  - Scrollable list of clipboard items
  - Settings gear icon (bottom-left corner)
- **Each clipboard item row shows**:
  - Content type icon (SF Symbols: `doc.plaintext`, `photo`, `link`, `folder`, `chevron.left.forwardslash.chevron.right`)
  - Preview (text snippet or image thumbnail)
  - Source app icon + name (small, secondary text)
  - Relative timestamp ("2m ago", "1h ago") using `.formatted(.relative(presentation: .named))`
  - Pin button (pin icon, toggles pin state)
  - Delete button (trash icon, appears on hover)
- **Interaction**:
  - Click an item → paste it to the frontmost app (write to `NSPasteboard` and simulate `Cmd+V`)
  - Arrow keys to navigate, Enter to paste selected item
  - Search filters items by text content in real-time using SwiftData `#Predicate`
- **SwiftUI features used**: `@Query` with dynamic filter, `.searchable`, `.animation`, `@Bindable`

### 3. Global Hotkeys
- Use **Carbon Hot Key API** (`RegisterEventHotKey`) for system-wide shortcuts
- Request Accessibility permission on first launch via `AXIsProcessTrusted()`
- If not trusted, show a dialog guiding user to System Settings > Privacy > Accessibility
- Default shortcuts:
  - `Cmd + Shift + V` → Open popup (paste from history)
  - `Cmd + Option + V` → Paste selected item as plain text (strips formatting)
- Shortcuts are configurable in Settings (stored in UserDefaults)
- Use a **ShortcutRecorder**-style view in settings for key binding capture

### 4. Menu Bar
- SwiftUI `MenuBarExtra` with a clipboard icon (SF Symbol: `clipboard`)
- Clicking the menu bar icon → opens the same centered popup
- The menu bar icon is the only persistent UI element (no Dock icon)

### 5. Settings View
Presented as a separate window using SwiftUI `Settings` scene with `TabView` (macOS standard preferences style):

**General**
- Start at Login (toggle) — uses `SMAppService.mainApp` for login item registration
- Max history items (stepper/picker: 100, 250, 500, 1000, 2000)

**Sound**
- Enable sound effect (toggle)
- Stop playing sound in Focus mode (toggle) — uses Focus mode status detection

**Keyboard Shortcuts**
- Paste shortcut: Key recorder field (default: `Cmd + Shift + V`)
- Paste as original text: Key recorder field (default: `Cmd + Option + V`)

**Data**
- Clear all history (button with confirmation alert)

### 6. Paste Functionality
- When user selects an item from the popup:
  1. Write the item's full `content` data back to `NSPasteboard.general`
  2. Dismiss the popup
  3. Simulate `Cmd+V` keypress via `CGEvent` to paste into the frontmost app
- "Paste as original text" strips RTF/HTML and pastes plain text only

### 7. Pin / Delete
- **Pin**: Toggle `isPinned` on the item. Pinned items show a filled pin icon and are never auto-removed
- **Delete**: Remove item from SwiftData with immediate delete (SwiftUI `.swipeActions` or hover-reveal trash button)

---

## File Structure

```
VoltPaste/
├── App/
│   ├── VoltPasteApp.swift              # App entry, MenuBarExtra, lifecycle
│   └── AppDelegate.swift               # NSApplicationDelegate for hotkey setup
├── Models/
│   ├── ClipboardItem.swift             # SwiftData @Model
│   └── ContentType.swift               # Enum for clipboard content types
├── Services/
│   ├── ClipboardMonitor.swift          # NSPasteboard polling + change detection
│   ├── HotKeyManager.swift             # Carbon hotkey registration
│   ├── PasteService.swift              # Write to pasteboard + simulate Cmd+V
│   ├── SoundManager.swift              # Sound effect playback + Focus mode check
│   └── LoginItemManager.swift          # SMAppService for start-at-login
├── Views/
│   ├── PopupWindow/
│   │   ├── PopupPanel.swift            # NSPanel subclass
│   │   ├── PopupView.swift             # Main popup SwiftUI view
│   │   ├── ClipboardItemRow.swift      # Single item row view
│   │   ├── SearchBar.swift             # Search field component
│   │   └── ContentTypeFilter.swift     # Filter chips
│   ├── Settings/
│   │   ├── SettingsView.swift          # Main settings container (TabView)
│   │   ├── GeneralSettingsView.swift   # General tab
│   │   ├── SoundSettingsView.swift     # Sound tab
│   │   ├── ShortcutSettingsView.swift  # Keyboard shortcuts tab
│   │   └── ShortcutRecorder.swift      # Key binding capture view
│   └── MenuBar/
│       └── MenuBarView.swift           # MenuBarExtra content
├── Utilities/
│   ├── KeyboardShortcut+Carbon.swift   # Carbon key code mappings
│   └── Extensions.swift                # Data hashing, image resizing, etc.
├── Resources/
│   ├── Assets.xcassets/                # App icon, colors
│   └── Sounds/
│       └── clip.aiff                   # Custom copy sound effect
└── Info.plist / Entitlements
```

---

## Implementation Phases

### Phase 1: Core Infrastructure
1. Set deployment target to macOS 15.0, enable Swift 6 strict concurrency, configure app as menu bar agent (`LSUIElement`)
2. Replace default `Item.swift` with `ClipboardItem` SwiftData `@Model`
3. Create `ContentType` enum
4. Implement `ClipboardMonitor` service (`@Observable`, `@MainActor`, polling + duplicate detection)
5. Set up `MenuBarExtra` with clipboard icon

### Phase 2: Popup Window
1. Create `PopupPanel` (NSPanel subclass)
2. Build `PopupView` with search bar, filter chips, and item list using `@Query`
3. Implement `ClipboardItemRow` with type icons, preview, timestamps
4. Wire up popup show/dismiss logic from menu bar click
5. Implement item selection → paste flow (`PasteService`)

### Phase 3: Global Hotkeys & Paste
1. Implement `HotKeyManager` with Carbon API
2. Add Accessibility permission check and prompt
3. Wire `Cmd+Shift+V` to show popup
4. Implement `Cmd+Option+V` for paste-as-plain-text
5. Implement CGEvent-based `Cmd+V` simulation after item selection

### Phase 4: Settings
1. Build `SettingsView` with `Settings` scene + `TabView` (General, Sound, Shortcuts sections)
2. Implement `ShortcutRecorder` for custom key binding capture
3. Implement `LoginItemManager` (start at login via SMAppService)
4. Implement `SoundManager` with custom sound + Focus mode detection
5. Wire settings to all services

### Phase 5: Pin, Delete & Polish
1. Add pin/unpin toggle on clipboard items
2. Add delete button (hover-revealed) on items
3. Add "Clear all history" in settings
4. Polish animations (popup appear/dismiss, item hover states) using SwiftUI `.animation` and `.transition`
5. Add empty state view with `ContentUnavailableView` when no history exists
6. Keyboard navigation (arrow keys + Enter) in popup

### Phase 6: Final
1. Add app icon to Assets
2. Bundle custom sound effect
3. Configure entitlements properly for sandbox
4. Test Accessibility permission flow
5. Test with various content types (rich text, images, files, URLs)

---

## Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Min target | macOS 15.0 | Access to latest SwiftUI/SwiftData APIs, Swift 6 |
| Concurrency | Swift 6 strict | Compile-time safety for data races, `@MainActor` isolation |
| Sandbox | Kept enabled | App Store compatibility; clipboard reading works in sandbox |
| Clipboard monitoring | Timer polling (0.5s) | No native clipboard change notification on macOS |
| Global hotkeys | Carbon API | Only reliable way to capture system-wide hotkeys |
| Popup style | NSPanel | Can float above other apps without stealing focus |
| Persistence | SwiftData | Native, `@Model`/`@Query`/`#Predicate` for type-safe queries |
| State management | @Observable | Modern, no `@Published` boilerplate |
| Image storage | Thumbnail + full data (`@Attribute(.externalStorage)`) | Large blobs stored outside SQLite, thumbnails for fast rendering |
| Empty states | `ContentUnavailableView` | Native macOS 15 component for empty/error states |
| Login item | SMAppService | Modern API, works with sandbox |
| Sound | Bundled .aiff | Custom subtle sound, respects Focus mode |

---

## Risks & Mitigations

1. **Accessibility permission UX**: Users may not know how to grant it → Provide clear instructions dialog with a button to open System Settings
2. **App Sandbox + CGEvent**: Simulating keypresses may require additional entitlements → Test early, may need `com.apple.security.temporary-exception.apple-events`
3. **Large clipboard data**: Images/files can be very large → `@Attribute(.externalStorage)` keeps blobs out of SQLite; thumbnails for display
4. **Focus mode detection**: Use system APIs to check Focus mode status → Graceful fallback if unavailable
5. **Clipboard polling performance**: 0.5s timer is lightweight but constant → Use `changeCount` comparison (single integer check, negligible CPU)
6. **Swift 6 strict concurrency**: Carbon API callbacks are not `Sendable` → Isolate with `@MainActor` and `nonisolated` bridging where needed
