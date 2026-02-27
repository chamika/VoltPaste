import SwiftUI
import SwiftData

struct PopupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipboardItem.timestamp, order: .reverse) private var allItems: [ClipboardItem]
    @State private var searchText = ""
    @State private var selectedType: ContentType?
    @State private var hoveredItemID: UUID?
    @State private var selectedIndex: Int = 0

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
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.return) {
            pasteSelectedItem()
            return .handled
        }
        .onChange(of: filteredItems.count) {
            selectedIndex = min(selectedIndex, max(filteredItems.count - 1, 0))
        }
        .onChange(of: searchText) {
            selectedIndex = 0
        }
        .onChange(of: selectedType) {
            selectedIndex = 0
        }
        .onAppear { installArrowKeyMonitor() }
        .onDisappear { removeArrowKeyMonitor() }
    }

    @State private var arrowKeyMonitor: Any?

    private func installArrowKeyMonitor() {
        arrowKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            guard searchText.isEmpty else { return event }

            if event.keyCode == 123 { // left arrow
                moveFilter(by: -1)
                return nil
            } else if event.keyCode == 124 { // right arrow
                moveFilter(by: 1)
                return nil
            }
            return event
        }
    }

    private func removeArrowKeyMonitor() {
        if let monitor = arrowKeyMonitor {
            NSEvent.removeMonitor(monitor)
            arrowKeyMonitor = nil
        }
    }

    // Filter tabs: [nil (All), .text, .image, .url, .file, .code]
    private var filterOptions: [ContentType?] {
        [nil] + ContentType.allCases.map { Optional($0) }
    }

    private func moveFilter(by offset: Int) {
        let options = filterOptions
        let currentIndex = options.firstIndex(where: { $0 == selectedType }) ?? 0
        let newIndex = currentIndex + offset
        guard newIndex >= 0, newIndex < options.count else { return }
        selectedType = options[newIndex]
    }

    private func moveSelection(by offset: Int) {
        guard !filteredItems.isEmpty else { return }
        let newIndex = selectedIndex + offset
        selectedIndex = max(0, min(newIndex, filteredItems.count - 1))
    }

    private func pasteSelectedItem() {
        guard !filteredItems.isEmpty, selectedIndex < filteredItems.count else { return }
        let item = filteredItems[selectedIndex]
        onItemSelected?(item, false)
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
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                ClipboardItemRow(
                                    item: item,
                                    isHovered: hoveredItemID == item.id,
                                    isSelected: selectedIndex == index,
                                    onSelect: { onItemSelected?(item, false) },
                                    onDelete: { deleteItem(item) },
                                    onTogglePin: { togglePin(item) }
                                )
                                .id(item.id)
                                .onHover { isHovered in
                                    hoveredItemID = isHovered ? item.id : nil
                                    if isHovered { selectedIndex = index }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: selectedIndex) {
                        guard selectedIndex < filteredItems.count else { return }
                        withAnimation(.easeInOut(duration: 0.15)) {
                            proxy.scrollTo(filteredItems[selectedIndex].id, anchor: .center)
                        }
                    }
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
