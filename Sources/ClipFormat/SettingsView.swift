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
                Toggle("Auto-detect Markdown", isOn: $prefs.autoDetectMarkdown)
                    .help("Skip conversion if clipboard doesn't look like Markdown.")

                Toggle("Play sound on convert", isOn: $prefs.playSound)

                Toggle("Show notification after convert", isOn: $prefs.showNotification)
            } header: {
                Text("Behavior")
            }

            Section {
                LabeledContent("Rich text (RTF)") {
                    Text("Word, Pages, Notes, Mail, Outlook, Slack")
                        .foregroundStyle(.secondary).font(.caption)
                }
                LabeledContent("HTML") {
                    Text("Notion, Google Docs, Linear, Confluence")
                        .foregroundStyle(.secondary).font(.caption)
                }
                LabeledContent("Plain text") {
                    Text("VS Code, Terminal, Discord, any text field")
                        .foregroundStyle(.secondary).font(.caption)
                }
            } header: {
                Text("Supported output formats")
            } footer: {
                Text("ClipFormat writes all three formats at once. The target app picks the richest one it supports.")
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

#Preview {
    SettingsView()
}
