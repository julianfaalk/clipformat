import AppKit
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem?
    private let hotkeyManager = HotkeyManager.shared
    private let prefs = PreferencesManager.shared

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        setupHotkey()
        requestNotificationPermission()
        OnboardingWindowController.showIfNeeded()
    }

    // MARK: - Menu Bar

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateMenuBarIcon(symbolName: "doc.richtext")
        rebuildMenu()
    }

    func rebuildMenu() {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "ClipFormat", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())

        let convertItem = NSMenuItem(
            title: "Convert Clipboard    ⌥⌘C",
            action: #selector(convertClipboard),
            keyEquivalent: ""
        )
        convertItem.target = self
        menu.addItem(convertItem)

        let stripItem = NSMenuItem(
            title: "Strip Formatting (plain text)  ⌥⌘X",
            action: #selector(stripFormatting),
            keyEquivalent: ""
        )
        stripItem.target = self
        menu.addItem(stripItem)

        // History submenu
        let history = ClipboardHistory.shared.entries
        if !history.isEmpty {
            let historyItem = NSMenuItem(title: "Recent Conversions", action: nil, keyEquivalent: "")
            let sub = NSMenu()
            for (idx, entry) in history.enumerated() {
                let item = NSMenuItem(
                    title: entry.preview,
                    action: #selector(restoreHistory(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.tag = idx
                let df = DateFormatter()
                df.timeStyle = .short
                item.toolTip = df.string(from: entry.date)
                sub.addItem(item)
            }
            historyItem.submenu = sub
            menu.addItem(historyItem)
        }

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        statusItem?.menu = menu
    }

    func updateMenuBarIcon(symbolName: String) {
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "ClipFormat")
            button.image?.isTemplate = true
        }
    }

    // MARK: - Hotkey

    func setupHotkey() {
        hotkeyManager.register()
        hotkeyManager.onActivate = { [weak self] in
            self?.convertClipboard()
        }

        // Second hotkey: ⌥⌘X for strip formatting
        hotkeyManager.registerSecondary(keyCode: 7) // X
        hotkeyManager.onSecondaryActivate = { [weak self] in
            self?.stripFormatting()
        }
    }

    // MARK: - Core: Convert Clipboard

    @objc func convertClipboard() {
        let source = ClipboardReader.read()

        // Empty clipboard
        if case .empty = source {
            flash(symbol: "exclamationmark.triangle", label: "⚠️ Empty", duration: 2)
            return
        }

        // Auto-detect: if plain text with no Markdown, skip unless user force-converts
        if case .plainText = source, prefs.autoDetectMarkdown {
            flash(symbol: "equal.circle", label: "Plain ✓", duration: 2)
            notify(title: "ClipFormat", body: "Already plain text — no conversion needed.")
            return
        }

        guard let result = FormatBridge.convert(source: source) else {
            flash(symbol: "exclamationmark.triangle", label: "⚠️ Error", duration: 2)
            return
        }

        // Preview mode
        if prefs.showPreview {
            PreviewWindowController.show(original: result.plain, html: result.html) { [weak self] in
                guard let self else { return }
                self.applyResult(result)
            }
            return
        }

        applyResult(result)
    }

    private func applyResult(_ result: FormatBridge.Result) {
        PasteboardWriter.write(html: result.html, attributed: result.attributed, plain: result.plain)
        ClipboardHistory.shared.add(original: result.plain, html: result.html)
        rebuildMenu()
        flash(symbol: "checkmark.circle.fill", label: result.sourceLabel, duration: 2)
        notify(title: "ClipFormat", body: "\(result.sourceLabel) — press ⌘V to paste.")
        if prefs.playSound { NSSound(named: .init("Pop"))?.play() }
    }

    // MARK: - UI Feedback

    func flash(symbol: String, label: String, duration: TimeInterval) {
        guard let button = statusItem?.button else { return }
        let origImage = button.image

        DispatchQueue.main.async {
            button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            button.image?.isTemplate = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            button.image = origImage
        }
    }

    // MARK: - Notifications

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notify(title: String, body: String) {
        guard prefs.showNotification else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }

    // MARK: - History

    @objc func restoreHistory(_ sender: NSMenuItem) {
        let entries = ClipboardHistory.shared.entries
        guard sender.tag < entries.count else { return }
        ClipboardHistory.shared.restore(entries[sender.tag])
        flash(symbol: "clock.arrow.circlepath", label: "↩︎ Restored", duration: 2)
        if prefs.playSound { NSSound(named: .init("Pop"))?.play() }
    }

    // MARK: - Strip Formatting

    @objc func stripFormatting() {
        let pasteboard = NSPasteboard.general
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else {
            flash(symbol: "exclamationmark.triangle", label: "⚠️ Empty", duration: 2)
            return
        }
        let stripped = MarkdownStripper.strip(text)
        pasteboard.clearContents()
        pasteboard.setString(stripped, forType: .string)
        flash(symbol: "text.alignleft", label: "Plain ✓", duration: 2)
        if prefs.playSound { NSSound(named: .init("Tink"))?.play() }
    }

    // MARK: - Settings

    @objc func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
