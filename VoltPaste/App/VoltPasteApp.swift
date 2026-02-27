import SwiftUI
import SwiftData

@main
struct VoltPasteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ClipboardItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        Settings {
            SettingsView()
                .modelContainer(sharedModelContainer)
        }
    }

    init() {
        // Delay setup to after app delegate is ready
        DispatchQueue.main.async { [self] in
            appDelegate.setupClipboardMonitor(with: sharedModelContainer)
        }
    }
}
