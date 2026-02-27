import AppKit

struct PasteService: Sendable {
    static func paste(item: ClipboardItem, asPlainText: Bool = false) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let contentType = item.resolvedContentType

        if asPlainText {
            if let text = String(data: item.content, encoding: .utf8) {
                pasteboard.setString(text, forType: .string)
            }
        } else {
            switch contentType {
            case .text, .code:
                if let text = String(data: item.content, encoding: .utf8) {
                    pasteboard.setString(text, forType: .string)
                }
            case .url:
                if let urlString = String(data: item.content, encoding: .utf8) {
                    pasteboard.setString(urlString, forType: .string)
                    if let url = URL(string: urlString) {
                        pasteboard.setString(url.absoluteString, forType: .URL)
                    }
                }
            case .image:
                pasteboard.setData(item.content, forType: .png)
            case .file:
                if let urlString = String(data: item.content, encoding: .utf8) {
                    pasteboard.setString(urlString, forType: .fileURL)
                }
            }
        }

        simulatePaste()
    }

    private static func simulatePaste() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let source = CGEventSource(stateID: .hidSystemState)

            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // V key
            keyDown?.flags = .maskCommand

            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            keyUp?.flags = .maskCommand

            keyDown?.post(tap: .cghidEventTap)
            keyUp?.post(tap: .cghidEventTap)
        }
    }
}
