import SwiftUI

struct SettingsView: View {
    @StateObject private var prefs = PreferencesManager.shared

    var body: some View {
        Form {
            Section {
                LabeledContent("Shortcut") {
                    HStack(spacing: 4) {
                        ForEach(["⌥", "⌘", "C"], id: \.self) { key in
                            Text(key)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                        }
                    }
                }

                LabeledContent("Workflow") {
                    Text("Copy from AI → Press \(prefs.shortcutLabel) → Paste anywhere")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            } header: {
                Text("Shortcut")
            }

            Section {
                LaunchAtLoginToggle()

                Toggle("Auto-detect Markdown", isOn: $prefs.autoDetectMarkdown)
                    .help("Skip conversion if clipboard doesn't look like Markdown.")

                Toggle("Preview before copying", isOn: $prefs.showPreview)
                    .help("Show a preview window to confirm before the clipboard is replaced.")

                Toggle("Play sound on convert", isOn: $prefs.playSound)

                Toggle("Show notification after convert", isOn: $prefs.showNotification)
            } header: {
                Text("Behavior")
            }

            Section {
                ShortcutRow(keys: ["⌥", "⌘", "C"], label: "Convert Clipboard")
                ShortcutRow(keys: ["⌥", "⌘", "X"], label: "Strip to Plain Text")
                ShortcutRow(keys: ["⌘", ","],        label: "Open Settings")
            } header: {
                Text("Shortcuts")
            }

            Section {
                AppCompatRow(icon: "doc.richtext",   label: "RTF",        apps: "Word, Pages, Notes, Mail, Outlook, Slack")
                AppCompatRow(icon: "globe",          label: "HTML",       apps: "Notion, Google Docs, Linear, Confluence, Coda")
                AppCompatRow(icon: "text.alignleft", label: "Plain text", apps: "VS Code, Terminal, Discord, all text fields")
            } header: {
                Text("Output formats (written simultaneously)")
            } footer: {
                Text("The target app automatically picks the richest format it supports.")
                    .foregroundStyle(.tertiary)
            }

            Section {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Author", value: "github.com/julianfaalk/clipformat")
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .padding(.vertical, 8)
    }
}

struct ShortcutRow: View {
    let keys: [String]
    let label: String
    var body: some View {
        LabeledContent(label) {
            HStack(spacing: 3) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }
}

struct AppCompatRow: View {
    let icon: String
    let label: String
    let apps: String
    var body: some View {
        LabeledContent(label) {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(.secondary)
                Text(apps).foregroundStyle(.secondary).font(.caption)
            }
        }
    }
}

/// Toggle that reads live SMAppService status (not @Published, so manual State).
struct LaunchAtLoginToggle: View {
    @State private var enabled = LaunchAtLoginManager.shared.isEnabled

    var body: some View {
        Toggle("Launch at Login", isOn: $enabled)
            .onChange(of: enabled) { _, val in
                val ? LaunchAtLoginManager.shared.enable()
                    : LaunchAtLoginManager.shared.disable()
            }
    }
}

#Preview {
    SettingsView()
}
