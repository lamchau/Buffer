import SwiftUI

/// Settings view for configuring Buffer preferences
struct SettingsView: View {
    @StateObject private var settings = SettingsViewModel()
    @State private var isRecording = false
    @State private var recordedKeyCode: UInt16 = 0
    @State private var recordedModifiers = HotkeyModifiers()
    @State private var showingTrimAlert = false
    @State private var pendingTier: HistoryLimit?
    @State private var recordingAction: ShortcutAction?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "keyboard")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
                Text("Buffer Settings")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            
            Divider()
            
            // Hotkey section
            VStack(alignment: .leading, spacing: 12) {
                Text("Keyboard Shortcut")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    // Current shortcut display
                    HStack(spacing: 4) {
                        Text(settings.hotkeyModifiers.displayString)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                        Text(keyCodeNames[settings.hotkeyKeyCode] ?? "?")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isRecording ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isRecording ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    
                    Button(action: { isRecording.toggle() }) {
                        Text(isRecording ? "Cancel" : "Change")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                }
                
                if isRecording {
                    Text("Press your new shortcut...")
                        .font(.system(size: 11))
                        .foregroundColor(.accentColor)
                }
            }
            
            Divider()
            
            // Preset shortcuts
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Presets")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    presetButton(label: "⇧⌘V", mods: HotkeyModifiers(shift: true, command: true), keyCode: 9)
                    presetButton(label: "⌥⌘V", mods: HotkeyModifiers(command: true, option: true), keyCode: 9)
                    presetButton(label: "⌃⇧V", mods: HotkeyModifiers(shift: true, control: true), keyCode: 9)
                    presetButton(label: "⌘B", mods: HotkeyModifiers(command: true), keyCode: 11)
                }
            }
            
            Divider()
            
            // System section
            VStack(alignment: .leading, spacing: 12) {
                Text("System")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Launch at Login")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Toggle("", isOn: $settings.launchAtLogin)
                        .labelsHidden()
                        .onChange(of: settings.launchAtLogin) { newValue in
                            SettingsManager.shared.toggleLaunchAtLogin(newValue)
                            DispatchQueue.main.async {
                                settings.launchAtLogin = SettingsManager.shared.launchAtLogin
                            }
                        }
                        .toggleStyle(.switch)
                }
                
                // History Size Section
                Divider()
                    .padding(.vertical, 4)
                
                Text("History Size")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    ForEach(HistoryLimit.allCases, id: \.self) { tier in
                        Button(action: { 
                            if tier.rawValue < settings.historyLimit.rawValue {
                                pendingTier = tier
                                showingTrimAlert = true
                            } else {
                                settings.historyLimit = tier
                                settings.save()
                            }
                        }) {
                            VStack(alignment: .center, spacing: 6) {
                                if settings.historyLimit == tier {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                        .font(.system(size: 14))
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary.opacity(0.3))
                                        .font(.system(size: 14))
                                }
                                
                                Text(tier.label)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(settings.historyLimit == tier ? .primary : .secondary)
                                
                                Text(tier.subtitle)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(settings.historyLimit == tier 
                                          ? Color.accentColor.opacity(0.1) 
                                          : Color(NSColor.controlBackgroundColor))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(settings.historyLimit == tier 
                                            ? Color.accentColor : Color.clear, lineWidth: settings.historyLimit == tier ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Window Shortcuts")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Reset to Defaults") {
                        settings.resetShortcuts()
                    }
                    .font(.system(size: 10))
                    .buttonStyle(.borderless)
                    .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    ForEach(ShortcutAction.allCases, id: \.self) { action in
                        ShortcutRow(
                            action: action,
                            shortcut: settings.shortcutBinding(for: action),
                            isRecording: Binding(
                                get: { recordingAction == action },
                                set: { if $0 { recordingAction = action } else { recordingAction = nil } }
                            )
                        )
                    }
                }
            }

            Divider()

            // About
            VStack(spacing: 6) {
                Text("Designed to disappear. Built to remember.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.5))
                    .italic()

                Text("Buffer \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") · by @samirpatil2000")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.4))

                HStack(spacing: 8) {
                    Link("⭐ Star on GitHub", destination: URL(string: "https://github.com/samirpatil2000/Buffer")!)
                        .font(.system(size: 10, weight: .medium))

                    Text("·")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.4))

                    Link("Report an Issue", destination: URL(string: "https://github.com/samirpatil2000/Buffer/issues/new")!)
                        .font(.system(size: 10, weight: .medium))
                }
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(width: 380)
        .alert("Reduce History Limit?", isPresented: $showingTrimAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reduce & Delete", role: .destructive) {
                if let tier = pendingTier {
                    settings.historyLimit = tier
                    settings.save()
                }
            }
        } message: {
            Text("This will permanently delete your oldest unbookmarked items to fit the new size. This action cannot be undone.")
        }
        .background(KeyRecorder(isRecording: Binding(
            get: { isRecording || recordingAction != nil },
            set: { if !$0 { isRecording = false; recordingAction = nil } }
        )) { keyCode, modifiers in
            if isRecording {
                settings.hotkeyKeyCode = keyCode
                settings.hotkeyModifiers = modifiers
                settings.save()
                isRecording = false
            } else if let action = recordingAction {
                settings.shortcuts[action] = KeyboardShortcut(keyCode: keyCode, modifiers: modifiers)
                settings.save()
                recordingAction = nil
            }
        })
    }
    
    private func presetButton(label: String, mods: HotkeyModifiers, keyCode: UInt16) -> some View {
        Button(action: {
            settings.hotkeyModifiers = mods
            settings.hotkeyKeyCode = keyCode
            settings.save()
        }) {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
    }
}

struct ShortcutRow: View {
    let action: ShortcutAction
    @Binding var shortcut: KeyboardShortcut
    @Binding var isRecording: Bool

    var body: some View {
        HStack {
            Text(action.displayName)
                .font(.system(size: 12))
                .frame(width: 130, alignment: .leading)

            Spacer()

            HStack(spacing: 4) {
                Text(shortcut.displayString)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isRecording ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isRecording ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
            )

            Button(isRecording ? "Cancel" : "Set") {
                isRecording.toggle()
            }
            .font(.system(size: 10))
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }
}

/// Records keyboard shortcuts when active
struct KeyRecorder: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onRecord: (UInt16, HotkeyModifiers) -> Void
    
    func makeNSView(context: Context) -> KeyRecorderView {
        let view = KeyRecorderView()
        view.onRecord = onRecord
        return view
    }
    
    func updateNSView(_ nsView: KeyRecorderView, context: Context) {
        nsView.isRecording = isRecording
        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }
}

class KeyRecorderView: NSView {
    var isRecording = false
    var onRecord: ((UInt16, HotkeyModifiers) -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window = self.window {
            // Set level to be above other apps but below system items
            window.level = .floating
            
            // Use a tiny delay to allow the window to be properly added to the window list
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        
        // Ignore modifier-only presses
        if event.keyCode == 56 || event.keyCode == 59 || event.keyCode == 58 || event.keyCode == 55 {
            return
        }
        
        let mods = HotkeyModifiers(
            shift: event.modifierFlags.contains(.shift),
            command: event.modifierFlags.contains(.command),
            option: event.modifierFlags.contains(.option),
            control: event.modifierFlags.contains(.control)
        )
        
        let specialKeys: Set<UInt16> = [36, 51, 53, 48]
        let hasModifier = mods.shift || mods.command || mods.option || mods.control
        if hasModifier || specialKeys.contains(event.keyCode) {
            onRecord?(event.keyCode, mods)
        }
    }
}

/// ViewModel wrapper for SettingsManager to avoid crashes
class SettingsViewModel: ObservableObject {
    @Published var hotkeyModifiers: HotkeyModifiers
    @Published var hotkeyKeyCode: UInt16
    @Published var launchAtLogin: Bool
    @Published var historyLimit: HistoryLimit
    @Published var shortcuts: [ShortcutAction: KeyboardShortcut] = [:]
    
    private let defaults = UserDefaults.standard
    private let hotkeyModifiersKey = "hotkeyModifiers"
    private let hotkeyKeyCodeKey = "hotkeyKeyCode"
    
    init() {
        // Load modifiers
        if let savedMods = defaults.array(forKey: hotkeyModifiersKey) as? [String] {
            self.hotkeyModifiers = HotkeyModifiers(from: savedMods)
        } else {
            self.hotkeyModifiers = HotkeyModifiers(shift: true, command: true, option: false, control: false)
        }
        
        // Load keycode (default to V = 9)
        let savedKeyCode = defaults.integer(forKey: hotkeyKeyCodeKey)
        self.hotkeyKeyCode = savedKeyCode > 0 ? UInt16(savedKeyCode) : 9
        
        // Load launch at login status from manager natively via SMAppService
        self.launchAtLogin = SettingsManager.shared.launchAtLogin
        
        // Load history limit
        let rawLimit = defaults.integer(forKey: "historyLimit")
        self.historyLimit = HistoryLimit(rawValue: rawLimit) ?? .essential

        if let data = defaults.data(forKey: "keyboardShortcuts"),
           let saved = try? JSONDecoder().decode([ShortcutAction: KeyboardShortcut].self, from: data) {
            self.shortcuts = saved
        } else {
            self.shortcuts = SettingsManager.defaultShortcuts
        }
    }
    
    func save() {
        defaults.set(hotkeyModifiers.toArray(), forKey: hotkeyModifiersKey)
        defaults.set(Int(hotkeyKeyCode), forKey: hotkeyKeyCodeKey)
        defaults.set(historyLimit.rawValue, forKey: "historyLimit")

        if let data = try? JSONEncoder().encode(shortcuts) {
            defaults.set(data, forKey: "keyboardShortcuts")
        }
        SettingsManager.shared.shortcuts = shortcuts

        SettingsManager.shared.hotkeyModifiers = hotkeyModifiers
        SettingsManager.shared.hotkeyKeyCode = hotkeyKeyCode
        SettingsManager.shared.historyLimit = historyLimit
        SettingsManager.shared.save()
        
        NotificationCenter.default.post(name: .bufferHotkeyChanged, object: nil)
        NotificationCenter.default.post(name: .bufferHistoryLimitChanged, object: nil)
    }

    func shortcutBinding(for action: ShortcutAction) -> Binding<KeyboardShortcut> {
        Binding(
            get: { self.shortcuts[action] ?? KeyboardShortcut(keyCode: action.defaultKeyCode, modifiers: action.defaultModifiers) },
            set: { self.shortcuts[action] = $0; self.save() }
        )
    }

    func resetShortcuts() {
        shortcuts = SettingsManager.defaultShortcuts
        save()
    }
}
