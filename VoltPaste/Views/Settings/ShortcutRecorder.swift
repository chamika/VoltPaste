import SwiftUI
import Carbon

struct ShortcutRecorder: View {
    @Binding var keyCode: Int
    @Binding var modifiers: Int
    @State private var isRecording = false

    var body: some View {
        Button {
            isRecording.toggle()
        } label: {
            Text(isRecording ? "Press shortcut..." : displayString)
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isRecording ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isRecording ? Color.accentColor : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onKeyPress { keyPress in
            guard isRecording else { return .ignored }

            let newModifiers = carbonModifiers(from: keyPress.modifiers)
            let newKeyCode = carbonKeyCode(from: keyPress.key.character) ?? keyCode

            self.keyCode = newKeyCode
            self.modifiers = newModifiers
            self.isRecording = false
            return .handled
        }
    }

    private var displayString: String {
        var parts: [String] = []

        if modifiers & cmdKey != 0 { parts.append("⌘") }
        if modifiers & shiftKey != 0 { parts.append("⇧") }
        if modifiers & optionKey != 0 { parts.append("⌥") }
        if modifiers & controlKey != 0 { parts.append("⌃") }

        parts.append(keyName(for: keyCode))
        return parts.joined()
    }

    private func carbonModifiers(from swiftUIModifiers: SwiftUI.EventModifiers) -> Int {
        var result = 0
        if swiftUIModifiers.contains(.command) { result |= cmdKey }
        if swiftUIModifiers.contains(.shift) { result |= shiftKey }
        if swiftUIModifiers.contains(.option) { result |= optionKey }
        if swiftUIModifiers.contains(.control) { result |= controlKey }
        return result
    }

    private func carbonKeyCode(from character: Character) -> Int? {
        let mapping: [Character: Int] = [
            "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D,
            "e": kVK_ANSI_E, "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H,
            "i": kVK_ANSI_I, "j": kVK_ANSI_J, "k": kVK_ANSI_K, "l": kVK_ANSI_L,
            "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O, "p": kVK_ANSI_P,
            "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
            "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X,
            "y": kVK_ANSI_Y, "z": kVK_ANSI_Z,
            "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3,
            "4": kVK_ANSI_4, "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7,
            "8": kVK_ANSI_8, "9": kVK_ANSI_9,
        ]
        return mapping[Character(String(character).lowercased())]
    }

    private func keyName(for code: Int) -> String {
        let names: [Int: String] = [
            kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D",
            kVK_ANSI_E: "E", kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H",
            kVK_ANSI_I: "I", kVK_ANSI_J: "J", kVK_ANSI_K: "K", kVK_ANSI_L: "L",
            kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O", kVK_ANSI_P: "P",
            kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
            kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X",
            kVK_ANSI_Y: "Y", kVK_ANSI_Z: "Z",
            kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3",
            kVK_ANSI_4: "4", kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7",
            kVK_ANSI_8: "8", kVK_ANSI_9: "9",
            kVK_Space: "Space", kVK_Return: "Return", kVK_Tab: "Tab",
            kVK_Delete: "Delete", kVK_Escape: "Esc",
        ]
        return names[code] ?? "?"
    }
}
