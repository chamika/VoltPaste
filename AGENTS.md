# VoltPaste — Agent & Architecture Guide

This document describes the architecture, file structure, data flow, and key technical decisions for the VoltPaste codebase. It is intended as a reference for AI coding agents and developers working on the project.

## Project Overview

- **Bundle ID**: `com.chamika.VoltPaste`
- **Platform**: macOS 15.0+
- **Language**: Swift 6, SwiftUI, SwiftData
- **Type**: Menu bar agent (`LSUIElement = YES`, no Dock icon)
- **Build**: Xcode, `PBXFileSystemSynchronizedRootGroup` — new files added under `VoltPaste/` are auto-included without modifying `project.pbxproj`

## Directory Structure

```
VoltPaste/
├── App/
│   ├── VoltPasteApp.swift        # @main entry point, ModelContainer, Settings scene
│   └── AppDelegate.swift         # NSStatusItem, PopupPanel, HotKeyManager wiring
├── Models/
│   ├── ClipboardItem.swift       # SwiftData @Model for clipboard history entries
│   └── ContentType.swift         # Enum: text | image | url | file | code
├── Services/
│   ├── ClipboardMonitor.swift    # NSPasteboard polling (0.5s timer), dedup, storage
│   ├── HotKeyManager.swift       # Carbon RegisterEventHotKey global shortcuts
│   ├── PasteService.swift        # Write to pasteboard + simulate Cmd+V via CGEvent
│   ├── SoundManager.swift        # AVAudioPlayer for clip.aiff, UserDefaults gate
│   └── LoginItemManager.swift    # SMAppService.mainApp register/unregister
├── Views/
│   ├── PopupWindow/
│   │   ├── PopupPanel.swift      # NSPanel subclass: floating, non-activating
│   │   ├── PopupView.swift       # SwiftUI root view for the popup
│   │   └── ClipboardItemRow.swift# Single row: icon, preview, source app, time, actions
│   └── Settings/
│       ├── SettingsView.swift    # TabView container
│       ├── GeneralSettingsView.swift
│       ├── SoundSettingsView.swift
│       ├── ShortcutSettingsView.swift
│       ├── ShortcutRecorder.swift # Custom key capture control using onKeyPress
│       └── DataSettingsView (inline in SettingsView)
├── Utilities/
│   └── Extensions.swift          # Data.sha256Hash, NSImage helpers, Date.relativeString
└── Resources/
    └── Sounds/
        └── clip.aiff             # Short click sound played on clipboard capture
```

## Architecture

### Application Lifecycle

```
VoltPasteApp (@main)
  └── creates ModelContainer (SwiftData, persistent)
  └── registers AppDelegate via @NSApplicationDelegateAdaptor
  └── exposes only Settings scene (no WindowGroup)
  └── deferred: calls appDelegate.setupClipboardMonitor(with:)

AppDelegate (NSApplicationDelegate)
  ├── setupStatusItem()     → NSStatusItem in menu bar
  ├── setupHotKeys()        → HotKeyManager.register(paste:pasteOriginal:)
  └── setupClipboardMonitor() → ClipboardMonitor.startMonitoring()
```

### Popup Lifecycle

1. `HotKeyManager` fires `onPasteHotKey` callback on main queue
2. `AppDelegate.togglePopup()` calls `showPopup()` or closes existing panel
3. `createPopupPanel()` builds `PopupView` wrapped in `NSHostingView` inside a `PopupPanel`
4. `PopupPanel.showCentered()` positions the panel, calls `makeKeyAndOrderFront(nil)`, installs event monitors
5. Panel closes on: Escape key, click outside, item selected, settings button pressed
6. On close, `stopMonitoringEvents()` removes all `NSEvent` monitors

### Data Flow

```
NSPasteboard (system)
  → ClipboardMonitor (polls every 0.5s)
      → detectContentType()  → ContentType
      → extractContent()     → (Data, preview, thumbnail?)
      → SHA256 hash          → dedup check via SwiftData #Predicate
      → insert ClipboardItem → ModelContext.save()
      → enforceLimit()       → delete oldest unpinned if over cap
      → onNewItem?()         → SoundManager.playClipSound()

User selects item in popup
  → PasteService.paste(item:asPlainText:)
      → NSPasteboard.clearContents() + write typed data
      → simulatePaste()      → CGEvent Cmd+V after 0.1s delay
```

### Keyboard Handling in Popup

The popup requires careful keyboard event routing because multiple layers compete:

| Key | Handler | Mechanism |
|-----|---------|-----------|
| Up/Down arrow | `PopupView` | `.onKeyPress(.upArrow/.downArrow)` on root VStack |
| Enter | `PopupView` | `.onKeyPress(.return)` |
| Left/Right arrow | `PopupView` | `NSEvent.addLocalMonitorForEvents` — required because `TextField` consumes these before SwiftUI sees them |
| Escape | `PopupPanel` | `NSEvent.addLocalMonitorForEvents` in `startMonitoringEvents()` |

The `selectionFromKeyboard` flag in `PopupView` distinguishes keyboard navigation from hover-driven selection changes, preventing unwanted scroll-to on hover.

## Key Technical Decisions

### NSPanel instead of SwiftUI Window
`PopupPanel` subclasses `NSPanel` with `.nonactivatingPanel` style mask. This allows the panel to receive key events (via `canBecomeKey: true`) without stealing focus from the previously active app — critical for Cmd+V to paste into the correct target.

### Carbon hotkeys (not `NSEvent.addGlobalMonitorForEvents`)
Global `NSEvent` monitors require Accessibility permission and still don't fire reliably before the event reaches other apps. Carbon `RegisterEventHotKey` is the standard macOS approach for app-level global hotkeys and is more reliable.

### SwiftData with `.externalStorage`
`ClipboardItem.content` and `thumbnailData` use `@Attribute(.externalStorage)` so large binary blobs (images) are stored outside the SQLite database, keeping queries fast.

### Deduplication via SHA256
Before inserting a new clipboard item, the monitor hashes the raw data with CryptoKit SHA256 and queries for an existing item with the same `contentHash`. If found, only the timestamp is updated (moving it to the top of history). The `#Unique` macro enforces this at the database level.

### Settings via `@Environment(\.openSettings)`
The Settings window is an `NSApp`-level window managed by the SwiftUI `Settings` scene. Opening it from inside an `NSPanel` requires `NSApp.activate(ignoringOtherApps: true)` first and then calling the `openSettings` environment action. `SettingsLink` doesn't work inside `NSPanel` (causes ViewBridge error 18).

### Accessibility permission
`AXIsProcessTrustedWithOptions` with the prompt option doesn't work under App Sandbox. Instead, the app uses `NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:..."))` to direct the user to the correct System Settings pane.

## UserDefaults Keys

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `pasteShortcutKeyCode` | Int | 9 (V) | Global paste popup hotkey — key code |
| `pasteShortcutModifiers` | Int | 0x1100 (Cmd+Shift) | Global paste popup hotkey — modifiers |
| `pasteOriginalShortcutKeyCode` | Int | 9 (V) | Paste as plain text hotkey — key code |
| `pasteOriginalShortcutModifiers` | Int | 0x900 (Cmd+Option) | Paste as plain text hotkey — modifiers |
| `maxHistoryItems` | Int | 500 | Maximum unpinned items retained |
| `soundEnabled` | Bool | true | Play clip.aiff on clipboard capture |
| `startAtLogin` | Bool | false | SMAppService login item registration |

## Tests

Tests live in `VoltPasteTests/VoltPasteTests.swift` and use the Swift Testing framework (`@Test`, `#expect`).

Test groups:
- `ContentTypeTests` — enum rawValue round-trips, display names, system images
- `DataExtensionTests` — SHA256 determinism, empty data, consistency
- `DateExtensionTests` — `relativeString` output for recent/old dates
- `ClipboardItemModelTests` — model initialisation, field defaults
- `HotKeyComboTests` — default combos, equality
- `LoginItemManagerTests` — initial state assertion

Run with: **Cmd+U** in Xcode, or `xcodebuild test -scheme VoltPaste`.

## Adding New Content Types

1. Add a case to `ContentType` in `Models/ContentType.swift` — provide `displayName`, `systemImage`, `tintColor`
2. Handle detection in `ClipboardMonitor.detectContentType(pasteboard:)`
3. Handle extraction in `ClipboardMonitor.extractContent(pasteboard:type:)`
4. Handle paste writing in `PasteService.paste(item:asPlainText:)`
5. Optionally handle preview display in `ClipboardItemRow.contentPreview`
