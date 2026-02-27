import Foundation
import SwiftData

@Model
final class ClipboardItem {
    #Unique<ClipboardItem>([\.contentHash])

    var id: UUID = UUID()
    @Attribute(.externalStorage) var content: Data = Data()
    var contentType: String = ContentType.text.rawValue
    var textPreview: String?
    @Attribute(.externalStorage) var thumbnailData: Data?
    var sourceAppBundleID: String?
    var sourceAppName: String?
    var timestamp: Date = Date()
    var isPinned: Bool = false
    var contentHash: String = ""

    var resolvedContentType: ContentType {
        ContentType(rawValue: contentType) ?? .text
    }

    init(
        content: Data,
        contentType: ContentType,
        textPreview: String? = nil,
        thumbnailData: Data? = nil,
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil,
        contentHash: String
    ) {
        self.id = UUID()
        self.content = content
        self.contentType = contentType.rawValue
        self.textPreview = textPreview
        self.thumbnailData = thumbnailData
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.timestamp = Date()
        self.isPinned = false
        self.contentHash = contentHash
    }
}
