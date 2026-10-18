import Carbon
import Foundation

// Carbon global hotkeys do not require Accessibility or Input Monitoring permissions.
final class HotkeyManager: ObservableObject {
    var onToggle: (() -> Void)?
    private var hotkeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    func register() {
        guard hotkeyRef == nil else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let context else { return noErr }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(context).takeUnretainedValue()
            var id = EventHotKeyID()
            let result = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID), nil,
                                           MemoryLayout<EventHotKeyID>.size, nil, &id)
            if result == noErr && id.signature == OSType(0x48555348) && id.id == 1 {
                DispatchQueue.main.async { manager.onToggle?() }
            }
            return noErr
        }, 1, &spec, pointer, &handlerRef)

        // Control + Option + Command + H
        let identifier = EventHotKeyID(signature: OSType(0x48555348), id: 1)
        RegisterEventHotKey(UInt32(kVK_ANSI_H),
                            UInt32(controlKey | optionKey | cmdKey),
                            identifier, GetApplicationEventTarget(), 0, &hotkeyRef)
    }

    deinit {
        if let hotkeyRef { UnregisterEventHotKey(hotkeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}
