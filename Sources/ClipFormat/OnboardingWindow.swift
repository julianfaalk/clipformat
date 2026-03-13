import AppKit
import SwiftUI

/// Shown once on first launch to explain the app.
struct OnboardingView: View {
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "doc.richtext")
                .font(.system(size: 52))
                .foregroundStyle(.blue)
                .padding(.top, 8)

            VStack(spacing: 8) {
                Text("Welcome to ClipFormat")
                    .font(.title2).bold()

                Text("Convert AI Markdown to rich text — in one keystroke.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Steps
            VStack(alignment: .leading, spacing: 14) {
                Step(number: "1", text: "Copy text from ChatGPT, Claude, or any AI tool")
                Step(number: "2", text: "Press **⌥⌘C** to convert the clipboard")
                Step(number: "3", text: "Paste normally with **⌘V** — fully formatted")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)

            // Compat note
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Works with Word, Pages, Notes, Mail, Notion, Google Docs, Slack, and more.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)

            Button(action: onDismiss) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 4)
        }
        .padding(28)
        .frame(width: 380)
    }
}

struct Step: View {
    let number: String
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(.blue, in: Circle())

            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Window controller

class OnboardingWindowController: NSWindowController {
    static func showIfNeeded() {
        let key = "cf_onboardingShown"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        let wc = OnboardingWindowController()
        wc.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    convenience init() {
        let view = OnboardingView(onDismiss: {
            NSApp.keyWindow?.close()
        })
        let hosting = NSHostingView(rootView: view)
        hosting.setFrameSize(hosting.fittingSize)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "Welcome to ClipFormat"
        win.contentView = hosting
        win.center()
        win.isReleasedWhenClosed = false

        self.init(window: win)
    }
}
