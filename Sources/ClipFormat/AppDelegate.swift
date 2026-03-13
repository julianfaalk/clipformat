import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var hotkeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        setupHotkey()
    }

    // MARK: - Menu Bar

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.richtext", accessibilityDescription: "ClipFormat")
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "ClipFormat", action: nil, keyEquivalent: "").isEnabled = false
        menu.addItem(.separator())

        let convertItem = NSMenuItem(title: "Convert & Format Clipboard  ⌥⌘C", action: #selector(convertClipboard), keyEquivalent: "")
        convertItem.target = self
        menu.addItem(convertItem)

        menu.addItem(.separator())
        menu.addItem(withTitle: "About", action: #selector(showAbout), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        statusItem?.menu = menu
    }

    // MARK: - Global Hotkey (⌥⌘C)

    func setupHotkey() {
        hotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // keyCode 8 = C, combined with Option (⌥) + Command (⌘)
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == [.option, .command] && event.keyCode == 8 {
                DispatchQueue.main.async {
                    self?.convertClipboard()
                }
            }
        }
    }

    // MARK: - Core Logic

    @objc func convertClipboard() {
        let pasteboard = NSPasteboard.general

        guard let text = pasteboard.string(forType: .string), !text.isEmpty else {
            flash("⚠️ No text")
            return
        }

        guard let attributed = MarkdownConverter.convert(text) else {
            flash("⚠️ Failed")
            return
        }

        // Write RTF + plain text fallback to clipboard
        pasteboard.clearContents()

        let rtfData = try? attributed.data(
            from: NSRange(location: 0, length: attributed.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )

        if let rtf = rtfData {
            pasteboard.setData(rtf, forType: .rtf)
        }

        // Keep plain text as fallback (for apps that only accept plain text)
        pasteboard.setString(text, forType: .string)

        flash("✅ Formatted!")
    }

    // MARK: - UI Feedback

    func flash(_ message: String) {
        guard let button = statusItem?.button else { return }
        let original = button.image
        button.image = nil
        button.title = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            button.title = ""
            button.image = original
        }
    }

    @objc func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "ClipFormat"
        alert.informativeText = "Converts Markdown (from ChatGPT, Claude, Gemini, etc.) to rich text on your clipboard.\n\nShortcut: ⌥⌘C\nThen paste normally with ⌘V."
        alert.runModal()
    }
}
