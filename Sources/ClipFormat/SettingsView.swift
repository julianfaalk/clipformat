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

                Toggle("Skip plain text (no formatting)", isOn: $prefs.autoDetectMarkdown)
                    .help("If the clipboard is plain text without Markdown or rich formatting, skip conversion and leave it as-is.")

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
                SourceRow(icon: "globe",           label: "Browser copy",  desc: "ChatGPT, Claude.ai, Notion, Google Docs → HTML stripped & normalized")
                SourceRow(icon: "doc.richtext",    label: "Rich text",     desc: "Word, Pages, Mail, TextEdit → RTF read, HTML generated")
                SourceRow(icon: "chevron.left.forwardslash.chevron.right", label: "Markdown", desc: "Plain text with ** / # / ``` → parsed to HTML + RTF")
                SourceRow(icon: "text.alignleft",  label: "Plain text",    desc: "Normalized, written in all formats for maximum compat")
            } header: {
                Text("Source detection (auto)")
            } footer: {
                Text("⌥⌘C reads whatever's on the clipboard and converts it to RTF + HTML + plain text simultaneously.")
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

struct SourceRow: View {
    let icon: String
    let label: String
    let desc: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.body)
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
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
