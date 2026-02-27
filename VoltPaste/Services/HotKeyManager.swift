import Carbon
import AppKit

final class HotKeyManager {
    struct KeyCombo: Equatable, Codable, Sendable {
        var keyCode: UInt32
        var modifiers: UInt32

        static let defaultPaste = KeyCombo(
            keyCode: UInt32(kVK_ANSI_V),
            modifiers: UInt32(cmdKey | shiftKey)
        )

        static let defaultPasteOriginal = KeyCombo(
            keyCode: UInt32(kVK_ANSI_V),
            modifiers: UInt32(cmdKey | optionKey)
        )
    }

    private var pasteHotKeyRef: EventHotKeyRef?
    private var pasteOriginalHotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    var onPasteHotKey: (() -> Void)?
    var onPasteOriginalHotKey: (() -> Void)?

    private static let pasteHotKeyID = EventHotKeyID(signature: fourCharCode("VPst"), id: 1)
    private static let pasteOriginalHotKeyID = EventHotKeyID(signature: fourCharCode("VPst"), id: 2)

    func register(paste: KeyCombo, pasteOriginal: KeyCombo) {
        unregisterAll()
        installEventHandler()
        registerHotKey(combo: paste, id: Self.pasteHotKeyID, ref: &pasteHotKeyRef)
        registerHotKey(combo: pasteOriginal, id: Self.pasteOriginalHotKeyID, ref: &pasteOriginalHotKeyRef)
    }

    func unregisterAll() {
        if let ref = pasteHotKeyRef {
            UnregisterEventHotKey(ref)
            pasteHotKeyRef = nil
        }
        if let ref = pasteOriginalHotKeyRef {
            UnregisterEventHotKey(ref)
            pasteOriginalHotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData, let event else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()

                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                DispatchQueue.main.async {
                    if hotKeyID.id == 1 {
                        manager.onPasteHotKey?()
                    } else if hotKeyID.id == 2 {
                        manager.onPasteOriginalHotKey?()
                    }
                }

                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
    }

    private func registerHotKey(combo: KeyCombo, id: EventHotKeyID, ref: inout EventHotKeyRef?) {
        RegisterEventHotKey(
            combo.keyCode,
            combo.modifiers,
            id,
            GetApplicationEventTarget(),
            0,
            &ref
        )
    }

    deinit {
        unregisterAll()
    }
}

private func fourCharCode(_ string: String) -> OSType {
    var result: OSType = 0
    for char in string.utf8.prefix(4) {
        result = result << 8 + OSType(char)
    }
    return result
}
