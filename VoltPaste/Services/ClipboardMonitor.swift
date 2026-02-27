import AppKit
import SwiftData
import Observation

@Observable
final class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let modelContainer: ModelContainer
    var onNewItem: (() -> Void)?

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        processClipboardContent(pasteboard: pasteboard)
    }

    @MainActor
    private func processClipboardContent(pasteboard: NSPasteboard) {
        let context = ModelContext(modelContainer)

        let contentType = detectContentType(pasteboard: pasteboard)
        guard let (data, preview, thumbnail) = extractContent(pasteboard: pasteboard, type: contentType) else { return }

        let hash = data.sha256Hash

        let existingPredicate = #Predicate<ClipboardItem> { item in
            item.contentHash == hash
        }
        let existingDescriptor = FetchDescriptor<ClipboardItem>(predicate: existingPredicate)

        if let existing = try? context.fetch(existingDescriptor).first {
            existing.timestamp = Date()
            try? context.save()
            onNewItem?()
            return
        }

        let frontmostApp = NSWorkspace.shared.frontmostApplication
        let item = ClipboardItem(
            content: data,
            contentType: contentType,
            textPreview: preview,
            thumbnailData: thumbnail,
            sourceAppBundleID: frontmostApp?.bundleIdentifier,
            sourceAppName: frontmostApp?.localizedName,
            contentHash: hash
        )

        context.insert(item)
        try? context.save()

        enforceLimit(context: context)
        onNewItem?()
    }

    private func enforceLimit(context: ModelContext) {
        let maxItems = UserDefaults.standard.integer(forKey: "maxHistoryItems")
        let limit = maxItems > 0 ? maxItems : 500

        let unpinnedPredicate = #Predicate<ClipboardItem> { item in
            item.isPinned == false
        }
        var descriptor = FetchDescriptor<ClipboardItem>(
            predicate: unpinnedPredicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        guard let allUnpinned = try? context.fetch(descriptor) else { return }

        if allUnpinned.count > limit {
            for item in allUnpinned.suffix(from: limit) {
                context.delete(item)
            }
            try? context.save()
        }
    }

    private func detectContentType(pasteboard: NSPasteboard) -> ContentType {
        let types = pasteboard.types ?? []

        if types.contains(.fileURL) {
            return .file
        }

        if types.contains(.png) || types.contains(.tiff) {
            if let _ = pasteboard.string(forType: .string) {
                // has both text and image, prefer image
            }
            return .image
        }

        if types.contains(.URL) || types.contains(NSPasteboard.PasteboardType("public.url")) {
            return .url
        }

        if let text = pasteboard.string(forType: .string) {
            if looksLikeURL(text) {
                return .url
            }
            if looksLikeCode(text) {
                return .code
            }
        }

        return .text
    }

    private func extractContent(pasteboard: NSPasteboard, type: ContentType) -> (Data, String?, Data?)? {
        switch type {
        case .text, .code:
            guard let text = pasteboard.string(forType: .string),
                  let data = text.data(using: .utf8)
            else { return nil }
            let preview = String(text.prefix(200))
            return (data, preview, nil)

        case .url:
            let urlString = pasteboard.string(forType: .string) ?? pasteboard.string(forType: NSPasteboard.PasteboardType("public.url")) ?? ""
            guard !urlString.isEmpty, let data = urlString.data(using: .utf8) else { return nil }
            let preview = String(urlString.prefix(200))
            return (data, preview, nil)

        case .image:
            guard let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) else { return nil }
            let thumbnail = generateThumbnail(from: imageData)
            return (imageData, nil, thumbnail)

        case .file:
            guard let urlString = pasteboard.string(forType: .fileURL),
                  let url = URL(string: urlString)
            else { return nil }
            let filename = url.lastPathComponent
            guard let data = urlString.data(using: .utf8) else { return nil }
            return (data, filename, nil)
        }
    }

    private func generateThumbnail(from imageData: Data) -> Data? {
        guard let image = NSImage(data: imageData) else { return nil }
        let thumbnail = image.resized(maxDimension: 200)
        return thumbnail.pngData
    }

    private func looksLikeURL(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.contains("\n") else { return false }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed) != nil
        }
        return false
    }

    private func looksLikeCode(_ text: String) -> Bool {
        let codeIndicators = [
            "func ", "class ", "struct ", "enum ", "import ",
            "def ", "return ", "const ", "let ", "var ",
            "if (", "for (", "while (", "switch ",
            "public ", "private ", "static ",
            "->", "=>", "&&", "||",
        ]

        let lines = text.components(separatedBy: .newlines)
        guard lines.count >= 2 else { return false }

        var score = 0
        let sample = text.prefix(1000)
        for indicator in codeIndicators {
            if sample.contains(indicator) { score += 1 }
        }

        let hasIndentation = lines.contains { $0.hasPrefix("    ") || $0.hasPrefix("\t") }
        if hasIndentation { score += 1 }

        if sample.contains("{") && sample.contains("}") { score += 1 }
        if sample.contains("(") && sample.contains(")") { score += 1 }

        return score >= 3
    }
}
