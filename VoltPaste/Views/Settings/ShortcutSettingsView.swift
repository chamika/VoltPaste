import SwiftUI

struct ShortcutSettingsView: View {
    @AppStorage("pasteShortcutKeyCode") private var pasteKeyCode: Int = 9 // V
    @AppStorage("pasteShortcutModifiers") private var pasteModifiers: Int = 0x1100 // cmd+shift

    @AppStorage("pasteOriginalShortcutKeyCode") private var pasteOriginalKeyCode: Int = 9 // V
    @AppStorage("pasteOriginalShortcutModifiers") private var pasteOriginalModifiers: Int = 0x900 // cmd+option

    var body: some View {
        Form {
            Section("Keyboard Shortcuts") {
                HStack {
                    Text("Paste from history")
                    Spacer()
                    ShortcutRecorder(
                        keyCode: $pasteKeyCode,
                        modifiers: $pasteModifiers
                    )
                }

                HStack {
                    Text("Paste as plain text")
                    Spacer()
                    ShortcutRecorder(
                        keyCode: $pasteOriginalKeyCode,
                        modifiers: $pasteOriginalModifiers
                    )
                }
            }

            Section {
                Text("Global shortcuts require Accessibility permission in System Settings > Privacy & Security > Accessibility.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Open Accessibility Settings") {
                    NSWorkspace.shared.open(
                        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    )
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
