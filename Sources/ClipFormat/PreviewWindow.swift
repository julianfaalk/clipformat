import AppKit
import SwiftUI
import WebKit

// MARK: - Preview View (WKWebView wrapper)

struct HTMLPreview: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.loadHTMLString(html, baseURL: nil)
        return wv
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - Preview SwiftUI View

struct PreviewView: View {
    let originalText: String
    let html: String
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @State private var showSource = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Preview")
                    .font(.headline)
                Spacer()
                Toggle("Source", isOn: $showSource)
                    .toggleStyle(.button)
                    .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            if showSource {
                ScrollView {
                    Text(originalText)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
            } else {
                HTMLPreview(html: html)
            }

            Divider()

            // Action bar
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.escape)
                Spacer()
                Button("Copy Formatted  ⌘↩") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }
}

// MARK: - Window Controller

class PreviewWindowController: NSWindowController {

    static func show(original: String, html: String, onConfirm: @escaping () -> Void) {
        let wc = PreviewWindowController(original: original, html: html, onConfirm: onConfirm)
        wc.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        // Keep a strong reference
        _retainedControllers.append(wc)
    }

    private static var _retainedControllers: [PreviewWindowController] = []

    convenience init(original: String, html: String, onConfirm: @escaping () -> Void) {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        win.title = "ClipFormat Preview"
        win.center()
        win.isReleasedWhenClosed = false
        win.minSize = NSSize(width: 400, height: 300)

        self.init(window: win)

        let view = PreviewView(
            originalText: original,
            html: html,
            onConfirm: { [weak self] in
                onConfirm()
                win.close()
                PreviewWindowController._retainedControllers.removeAll { $0 === self }
            },
            onCancel: { [weak self] in
                win.close()
                PreviewWindowController._retainedControllers.removeAll { $0 === self }
            }
        )
        win.contentView = NSHostingView(rootView: view)
    }
}
