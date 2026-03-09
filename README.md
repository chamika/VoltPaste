# VoltPaste

A macOS clipboard history manager. Lives in your menu bar, lets you search and paste from your clipboard history with a Spotlight-like popup.

## Features

- **Clipboard history** — automatically captures text, images, URLs, files, and code snippets
- **Spotlight-like popup** — centered floating panel with instant search and content type filters
- **Keyboard-driven** — navigate with arrow keys, paste with Enter, switch filter tabs with left/right arrows
- **Pin items** — keep important clips pinned so they never get deleted
- **Source app tracking** — shows which app each item was copied from
- **Paste as plain text** — strips formatting when pasting
- **Sound feedback** — optional click sound on new clipboard capture
- **Start at Login** — system login item support
- **Configurable history limit** — default 500 items, oldest unpinned items auto-purged
- **Custom keyboard shortcuts** — rebind global hotkeys from Settings

## Requirements

- macOS 15.0 or later
- Accessibility permission (required for global hotkeys and paste simulation)

## Building

Open `VoltPaste.xcodeproj` in Xcode 16+ and build/run with the `VoltPaste` scheme.

You will need to update the team in Signing & Capabilities to your own Apple Developer account before building.

## Usage

### Opening the popup

- Press **Cmd+Shift+V** (default) to toggle the clipboard history popup
- Click the clipboard icon in the menu bar

### Navigating the popup

| Key | Action |
|-----|--------|
| Up / Down arrows | Move selection through items |
| Left / Right arrows | Switch content type filter tabs (when search is empty) |
| Enter | Paste selected item |
| Escape | Close popup |

### Item actions

Hover over an item or select it with the keyboard to reveal:

- **Pin button** — keeps the item permanently (orange pin = pinned)
- **Delete button** — removes the item from history

### Settings

Click the gear icon at the bottom-left of the popup, or open via menu bar.

- **General** — start at login, history item limit
- **Sound** — toggle clipboard capture sound, Focus mode suppression
- **Shortcuts** — rebind global hotkeys, grant Accessibility permission
- **Data** — clear all clipboard history

## Permissions

VoltPaste requires **Accessibility** permission to:
1. Register global keyboard shortcuts (Carbon `RegisterEventHotKey`)
2. Simulate Cmd+V to paste items into the frontmost app

Grant it in **System Settings > Privacy & Security > Accessibility**, or click **Grant Permission** in the Shortcuts settings tab.
