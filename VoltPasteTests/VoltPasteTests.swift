import Testing
import Foundation
@testable import VoltPaste

struct ContentTypeTests {
    @Test func allCasesHaveDisplayNames() {
        for type in ContentType.allCases {
            #expect(!type.displayName.isEmpty)
        }
    }

    @Test func allCasesHaveSystemImages() {
        for type in ContentType.allCases {
            #expect(!type.systemImage.isEmpty)
        }
    }

    @Test func rawValuesAreCorrect() {
        #expect(ContentType.text.rawValue == "text")
        #expect(ContentType.image.rawValue == "image")
        #expect(ContentType.url.rawValue == "url")
        #expect(ContentType.file.rawValue == "file")
        #expect(ContentType.code.rawValue == "code")
    }

    @Test func contentTypeFromRawValue() {
        #expect(ContentType(rawValue: "text") == .text)
        #expect(ContentType(rawValue: "image") == .image)
        #expect(ContentType(rawValue: "url") == .url)
        #expect(ContentType(rawValue: "invalid") == nil)
    }
}

struct DataExtensionTests {
    @Test func sha256HashIsConsistent() {
        let data = "Hello, World!".data(using: .utf8)!
        let hash1 = data.sha256Hash
        let hash2 = data.sha256Hash
        #expect(hash1 == hash2)
    }

    @Test func sha256HashIsDifferentForDifferentData() {
        let data1 = "Hello".data(using: .utf8)!
        let data2 = "World".data(using: .utf8)!
        #expect(data1.sha256Hash != data2.sha256Hash)
    }

    @Test func sha256HashHasCorrectLength() {
        let data = "test".data(using: .utf8)!
        let hash = data.sha256Hash
        #expect(hash.count == 64) // SHA256 produces 64 hex characters
    }

    @Test func emptyDataProducesHash() {
        let data = Data()
        let hash = data.sha256Hash
        #expect(!hash.isEmpty)
        #expect(hash.count == 64)
    }
}

struct DateExtensionTests {
    @Test func relativeStringIsNotEmpty() {
        let date = Date()
        #expect(!date.relativeString.isEmpty)
    }

    @Test func pastDateProducesRelativeString() {
        let date = Date(timeIntervalSinceNow: -3600) // 1 hour ago
        let relative = date.relativeString
        #expect(!relative.isEmpty)
    }
}

struct ClipboardItemModelTests {
    @Test func initializesCorrectly() {
        let data = "test content".data(using: .utf8)!
        let item = ClipboardItem(
            content: data,
            contentType: .text,
            textPreview: "test content",
            contentHash: data.sha256Hash
        )

        #expect(item.contentType == "text")
        #expect(item.textPreview == "test content")
        #expect(item.isPinned == false)
        #expect(item.sourceAppBundleID == nil)
        #expect(item.thumbnailData == nil)
    }

    @Test func resolvedContentType() {
        let data = "https://example.com".data(using: .utf8)!
        let item = ClipboardItem(
            content: data,
            contentType: .url,
            textPreview: "https://example.com",
            contentHash: data.sha256Hash
        )

        #expect(item.resolvedContentType == .url)
    }

    @Test func resolvedContentTypeFallsBackToText() {
        let data = Data()
        let item = ClipboardItem(
            content: data,
            contentType: .text,
            contentHash: data.sha256Hash
        )
        item.contentType = "unknown"

        #expect(item.resolvedContentType == .text)
    }
}

struct HotKeyComboTests {
    @Test func defaultPasteCombo() {
        let combo = HotKeyManager.KeyCombo.defaultPaste
        #expect(combo.keyCode == 9) // V key
    }

    @Test func defaultPasteOriginalCombo() {
        let combo = HotKeyManager.KeyCombo.defaultPasteOriginal
        #expect(combo.keyCode == 9) // V key
    }

    @Test func combosAreEquatable() {
        let combo1 = HotKeyManager.KeyCombo(keyCode: 9, modifiers: 0x1100)
        let combo2 = HotKeyManager.KeyCombo(keyCode: 9, modifiers: 0x1100)
        let combo3 = HotKeyManager.KeyCombo(keyCode: 9, modifiers: 0x900)

        #expect(combo1 == combo2)
        #expect(combo1 != combo3)
    }

    @Test func combosAreCodable() throws {
        let combo = HotKeyManager.KeyCombo.defaultPaste
        let encoded = try JSONEncoder().encode(combo)
        let decoded = try JSONDecoder().decode(HotKeyManager.KeyCombo.self, from: encoded)
        #expect(combo == decoded)
    }
}

struct LoginItemManagerTests {
    @Test func canInstantiate() {
        let manager = LoginItemManager()
        // Just verify it doesn't crash
        _ = manager.isEnabled
    }
}
