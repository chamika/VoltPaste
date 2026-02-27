import SwiftUI
import SwiftData

struct PopupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipboardItem.timestamp, order: .reverse) private var allItems: [ClipboardItem]
    @State private var searchText = ""
    @State private var selectedType: ContentType?
    @State private var hoveredItemID: UUID?

    @Environment(\.openSettings) private var openSettings
    var onItemSelected: ((ClipboardItem, Bool) -> Void)?
    var onDismiss: (() -> Void)?

    private var filteredItems: [ClipboardItem] {
        var items = allItems

        if let type = selectedType {
            items = items.filter { $0.contentType == type.rawValue }
        }

        if !searchText.isEmpty {
            items = items.filter { item in
                item.textPreview?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }

        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            filterBar
            Divider()
            itemList
            bottomBar
        }
        .frame(width: 680, height: 500)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search clipboard history...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterChip(title: "All", isSelected: selectedType == nil) {
                    selectedType = nil
                }
                ForEach(ContentType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.displayName,
                        systemImage: type.systemImage,
                        isSelected: selectedType == type
                    ) {
                        selectedType = selectedType == type ? nil : type
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var itemList: some View {
        Group {
            if filteredItems.isEmpty {
                ContentUnavailableView {
                    Label(
                        searchText.isEmpty ? "No Clipboard History" : "No Results",
                        systemImage: searchText.isEmpty ? "clipboard" : "magnifyingglass"
                    )
                } description: {
                    Text(searchText.isEmpty ? "Copy something to get started." : "Try a different search term.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredItems) { item in
                            ClipboardItemRow(
                                item: item,
                                isHovered: hoveredItemID == item.id,
                                onSelect: { onItemSelected?(item, false) },
                                onDelete: { deleteItem(item) },
                                onTogglePin: { togglePin(item) }
                            )
                            .onHover { isHovered in
                                hoveredItemID = isHovered ? item.id : nil
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            Button {
                onDismiss?()
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings")

            Spacer()

            Text("\(filteredItems.count) items")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func deleteItem(_ item: ClipboardItem) {
        withAnimation {
            modelContext.delete(item)
            try? modelContext.save()
        }
    }

    private func togglePin(_ item: ClipboardItem) {
        item.isPinned.toggle()
        try? modelContext.save()
    }
}

struct FilterChip: View {
    let title: String
    var systemImage: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 10))
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
            .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
