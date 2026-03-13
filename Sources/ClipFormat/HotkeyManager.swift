import Carbon
import AppKit

/// Registers a global hotkey via Carbon's RegisterEventHotKey.
/// More reliable than NSEvent.addGlobalMonitorForEvents across all apps.
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyRef2: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    var onActivate: (() -> Void)?
    var onSecondaryActivate: (() -> Void)?

    private init() {
        installEventHandler()
    }

    /// Register ⌥⌘C (Option + Command + C) as the global hotkey.
    /// keyCode 8 = C on US/ISO keyboards.
    func register(keyCode: UInt32 = 8, modifiers: UInt32 = UInt32(cmdKey | optionKey)) {
        // Unregister previous binding
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }

        var id = EventHotKeyID(signature: OSType(0x434C4650), id: 1) // 'CLFP'
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            id,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            print("ClipFormat: Hotkey registration failed (OSStatus \(status))")
        }
    }

    /// Register a secondary hotkey (⌥⌘ + keyCode).
    func registerSecondary(keyCode: UInt32, modifiers: UInt32 = UInt32(cmdKey | optionKey)) {
        if let ref = hotKeyRef2 { UnregisterEventHotKey(ref); hotKeyRef2 = nil }
        var id = EventHotKeyID(signature: OSType(0x434C4651), id: 2) // 'CLFQ'
        RegisterEventHotKey(keyCode, modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef2)
    }

    private func installEventHandler() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let ptr = userData, let event = event else { return noErr }
                let mgr = Unmanaged<HotkeyManager>.fromOpaque(ptr).takeUnretainedValue()

                var hkID = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                  EventParamType(typeEventHotKeyID), nil,
                                  MemoryLayout<EventHotKeyID>.size, nil, &hkID)

                DispatchQueue.main.async {
                    if hkID.id == 1 { mgr.onActivate?() }
                    else if hkID.id == 2 { mgr.onSecondaryActivate?() }
                }
                return noErr
            },
            1,
            &eventSpec,
            selfPtr,
            &eventHandlerRef
        )
    }

    deinit {
        if let ref = hotKeyRef  { UnregisterEventHotKey(ref) }
        if let ref = hotKeyRef2 { UnregisterEventHotKey(ref) }
        if let ref = eventHandlerRef { RemoveEventHandler(ref) }
    }
}
