import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isHovered: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onTogglePin: () -> Void

    private var contentType: ContentType {
        item.resolvedContentType
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                typeIcon
                contentPreview
                Spacer()
                trailingInfo
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var typeIcon: some View {
        Image(systemName: contentType.systemImage)
            .font(.system(size: 16))
            .foregroundStyle(contentType.tintColor)
            .frame(width: 24, height: 24)
    }

    @ViewBuilder
    private var contentPreview: some View {
        VStack(alignment: .leading, spacing: 2) {
            switch contentType {
            case .image:
                if let thumbnailData = item.thumbnailData,
                   let nsImage = NSImage(data: thumbnailData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Text("Image")
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                }
            default:
                if let preview = item.textPreview {
                    Text(preview)
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }
            }

            if let appName = item.sourceAppName {
                Text(appName)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var trailingInfo: some View {
        HStack(spacing: 8) {
            Text(item.timestamp.relativeString)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)

            if isHovered || item.isPinned {
                Button(action: onTogglePin) {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 12))
                        .foregroundStyle(item.isPinned ? .orange : .secondary)
                }
                .buttonStyle(.plain)
                .help(item.isPinned ? "Unpin" : "Pin")
            }

            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
        }
    }
}
