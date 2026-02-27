import SwiftUI
import SwiftData

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            SoundSettingsView()
                .tabItem {
                    Label("Sound", systemImage: "speaker.wave.2")
                }
            ShortcutSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
            DataSettingsView()
                .tabItem {
                    Label("Data", systemImage: "externaldrive")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct DataSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showClearConfirmation = false

    var body: some View {
        Form {
            Section("Clipboard History") {
                Button("Clear All History", role: .destructive) {
                    showClearConfirmation = true
                }
                .alert("Clear All History?", isPresented: $showClearConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Clear All", role: .destructive) {
                        clearHistory()
                    }
                } message: {
                    Text("This will permanently delete all clipboard history items. Pinned items will also be removed.")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func clearHistory() {
        do {
            try modelContext.delete(model: ClipboardItem.self)
            try modelContext.save()
        } catch {
            print("Failed to clear history: \(error)")
        }
    }
}
