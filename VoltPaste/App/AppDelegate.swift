import AppKit
import SwiftUI
import SwiftData

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popupPanel: PopupPanel?
    private let hotKeyManager = HotKeyManager()
    private var clipboardMonitor: ClipboardMonitor?
    private let soundManager = SoundManager()
    var modelContainer: ModelContainer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupHotKeys()
        checkAccessibilityPermission()
    }

    func setupClipboardMonitor(with container: ModelContainer) {
        self.modelContainer = container
        clipboardMonitor = ClipboardMonitor(modelContainer: container)
        clipboardMonitor?.onNewItem = { [weak self] in
            self?.soundManager.playClipSound()
        }
        clipboardMonitor?.startMonitoring()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "VoltPaste")
            button.action = #selector(statusItemClicked)
            button.target = self
        }
    }

    @objc private func statusItemClicked() {
        togglePopup()
    }

    func togglePopup() {
        if let panel = popupPanel, panel.isVisible {
            panel.close()
        } else {
            showPopup()
        }
    }

    func showPopup() {
        if popupPanel == nil {
            createPopupPanel()
        }
        popupPanel?.showCentered()
    }

    func hidePopup() {
        popupPanel?.close()
    }

    private func createPopupPanel() {
        guard let container = modelContainer else { return }

        let popupView = PopupView(
            onItemSelected: { [weak self] item, asPlainText in
                self?.hidePopup()
                PasteService.paste(item: item, asPlainText: asPlainText)
            },
            onSettingsTapped: {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        )
        .modelContainer(container)

        let hostingView = NSHostingView(rootView: popupView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 680, height: 500)

        let panel = PopupPanel(contentRect: NSRect(x: 0, y: 0, width: 680, height: 500))
        panel.contentView = hostingView
        self.popupPanel = panel
    }

    private func setupHotKeys() {
        let pasteKeyCode = UserDefaults.standard.integer(forKey: "pasteShortcutKeyCode")
        let pasteModifiers = UserDefaults.standard.integer(forKey: "pasteShortcutModifiers")
        let pasteOriginalKeyCode = UserDefaults.standard.integer(forKey: "pasteOriginalShortcutKeyCode")
        let pasteOriginalModifiers = UserDefaults.standard.integer(forKey: "pasteOriginalShortcutModifiers")

        let pasteCombo: HotKeyManager.KeyCombo
        if pasteKeyCode != 0 {
            pasteCombo = HotKeyManager.KeyCombo(keyCode: UInt32(pasteKeyCode), modifiers: UInt32(pasteModifiers))
        } else {
            pasteCombo = .defaultPaste
        }

        let pasteOriginalCombo: HotKeyManager.KeyCombo
        if pasteOriginalKeyCode != 0 {
            pasteOriginalCombo = HotKeyManager.KeyCombo(keyCode: UInt32(pasteOriginalKeyCode), modifiers: UInt32(pasteOriginalModifiers))
        } else {
            pasteOriginalCombo = .defaultPasteOriginal
        }

        hotKeyManager.onPasteHotKey = { [weak self] in
            self?.togglePopup()
        }

        hotKeyManager.onPasteOriginalHotKey = { [weak self] in
            self?.showPopup()
        }

        hotKeyManager.register(paste: pasteCombo, pasteOriginal: pasteOriginalCombo)
    }

    private func checkAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            print("VoltPaste needs Accessibility permission for global hotkeys.")
        }
    }
}
