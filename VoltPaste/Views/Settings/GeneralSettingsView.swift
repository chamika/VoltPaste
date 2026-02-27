import SwiftUI

struct GeneralSettingsView: View {
    @State private var loginItemManager = LoginItemManager()
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 500

    private let historyLimits = [100, 250, 500, 1000, 2000]

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Start at Login", isOn: $loginItemManager.isEnabled)
            }

            Section("Storage") {
                Picker("Maximum history items", selection: $maxHistoryItems) {
                    ForEach(historyLimits, id: \.self) { limit in
                        Text("\(limit)").tag(limit)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
