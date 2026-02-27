import SwiftUI

enum ContentType: String, CaseIterable, Codable, Sendable {
    case text
    case image
    case url
    case file
    case code

    var displayName: String {
        switch self {
        case .text: "Text"
        case .image: "Images"
        case .url: "URLs"
        case .file: "Files"
        case .code: "Code"
        }
    }

    var systemImage: String {
        switch self {
        case .text: "doc.plaintext"
        case .image: "photo"
        case .url: "link"
        case .file: "folder"
        case .code: "chevron.left.forwardslash.chevron.right"
        }
    }

    var tintColor: Color {
        switch self {
        case .text: .primary
        case .image: .purple
        case .url: .blue
        case .file: .orange
        case .code: .green
        }
    }
}
