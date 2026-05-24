import Foundation

enum ShortcutAction: String, CaseIterable, Codable {
    case paste = "paste"
    case copy = "copy"
    case delete = "delete"
    case pin = "pin"
    case bookmark = "bookmark"
    case saveImage = "saveImage"
    case addTag = "addTag"

    var displayName: String {
        switch self {
        case .paste: return "Paste Item"
        case .copy: return "Copy to Clipboard"
        case .delete: return "Delete Item"
        case .pin: return "Pin/Unpin"
        case .bookmark: return "Bookmark"
        case .saveImage: return "Save Image"
        case .addTag: return "Add Tag"
        }
    }

    var defaultKeyCode: UInt16 {
        switch self {
        case .paste: return 36      // Return
        case .copy: return 8        // C
        case .delete: return 51     // Delete
        case .pin: return 35        // P
        case .bookmark: return 11   // B
        case .saveImage: return 1   // S
        case .addTag: return 17     // T
        }
    }

    var defaultModifiers: HotkeyModifiers {
        switch self {
        case .paste:
            return HotkeyModifiers()
        case .copy:
            return HotkeyModifiers(command: true)
        case .delete:
            return HotkeyModifiers(command: true)
        case .pin:
            return HotkeyModifiers(command: true)
        case .bookmark:
            return HotkeyModifiers(command: true)
        case .saveImage:
            return HotkeyModifiers(command: true)
        case .addTag:
            return HotkeyModifiers(command: true)
        }
    }
}

struct KeyboardShortcut: Codable, Equatable {
    var keyCode: UInt16
    var modifiers: HotkeyModifiers

    var displayString: String {
        let modStr = modifiers.displayString
        let keyName = keyCodeNames[keyCode] ?? "?"
        if keyCode == 36 { return modStr + "↩" }
        if keyCode == 51 { return modStr + "⌫" }
        if keyCode == 53 { return modStr + "⎋" }
        if keyCode == 48 { return modStr + "⇥" }
        return modStr + keyName
    }
}
