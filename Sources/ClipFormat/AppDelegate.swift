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
    }

    // MARK: - Core: Convert Clipboard

    @objc func convertClipboard() {
        let pasteboard = NSPasteboard.general

        guard let text = pasteboard.string(forType: .string), !text.isEmpty else {
            flash(symbol: "exclamationmark.triangle", label: "⚠️ Empty", duration: 2)
            return
        }

        // Auto-detect: skip if no markdown found
        if prefs.autoDetectMarkdown && !MarkdownConverter.looksLikeMarkdown(text) {
            flash(symbol: "xmark.circle", label: "≠ MD", duration: 2)
            notify(title: "ClipFormat", body: "No Markdown detected in clipboard.")
            return
        }

        let html = MarkdownConverter.toHTML(text)

        guard let attributed = MarkdownConverter.htmlToAttributedString(html) else {
            flash(symbol: "exclamationmark.triangle", label: "⚠️ Error", duration: 2)
            return
        }

        PasteboardWriter.write(html: html, attributed: attributed, plain: text)

        flash(symbol: "checkmark.circle.fill", label: "✅", duration: 2)
        notify(title: "ClipFormat", body: "Clipboard formatted — press ⌘V to paste.")

        if prefs.playSound {
            NSSound(named: .init("Pop"))?.play()
        }
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

    // MARK: - Settings

    @objc func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
