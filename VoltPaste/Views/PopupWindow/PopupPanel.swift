import AppKit
import SwiftUI

final class PopupPanel: NSPanel {
    private var clickOutsideMonitor: Any?
    private var escapeMonitor: Any?

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = false
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.animationBehavior = .utilityWindow
    }

    override var canBecomeKey: Bool { true }

    func showCentered() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelSize = self.frame.size
        let x = screenFrame.origin.x + (screenFrame.width - panelSize.width) / 2
        let y = screenFrame.origin.y + (screenFrame.height - panelSize.height) / 2 + 100
        self.setFrameOrigin(NSPoint(x: x, y: y))
        self.makeKeyAndOrderFront(nil)
        startMonitoringEvents()
    }

    override func close() {
        stopMonitoringEvents()
        super.close()
    }

    private func startMonitoringEvents() {
        // Close when clicking outside the panel
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }

        // Close on Escape key
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.close()
                return nil
            }
            return event
        }
    }

    private func stopMonitoringEvents() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
        if let monitor = escapeMonitor {
            NSEvent.removeMonitor(monitor)
            escapeMonitor = nil
        }
    }

    deinit {
        stopMonitoringEvents()
    }
}

struct PopupPanelManager {
    private var panel: PopupPanel?

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    mutating func setup<Content: View>(content: Content) {
        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = NSRect(x: 0, y: 0, width: 680, height: 500)

        let panel = PopupPanel(contentRect: NSRect(x: 0, y: 0, width: 680, height: 500))
        panel.contentView = hostingView
        self.panel = panel
    }

    func show() {
        panel?.showCentered()
    }

    func hide() {
        panel?.close()
    }

    func toggle() {
        if panel?.isVisible == true {
            hide()
        } else {
            show()
        }
    }
}
