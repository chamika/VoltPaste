import SwiftUI

struct SoundSettingsView: View {
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("soundInFocusMode") private var soundInFocusMode = false

    var body: some View {
        Form {
            Section("Sound Effects") {
                Toggle("Enable sound effect", isOn: $soundEnabled)
                Toggle("Stop playing sound in Focus mode", isOn: $soundInFocusMode)
                    .disabled(!soundEnabled)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
