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

            Section("Accessibility Permission") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Global shortcuts require Accessibility permission.")
                            .font(.callout)
                        Text("System Settings > Privacy & Security > Accessibility")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if AppDelegate.isAccessibilityGranted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Grant Permission") {
                            AppDelegate.promptAccessibilityPermission()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
