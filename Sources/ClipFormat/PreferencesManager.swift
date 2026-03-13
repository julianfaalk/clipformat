import Foundation
import SwiftUI

final class PreferencesManager: ObservableObject {
    static let shared = PreferencesManager()

    @Published var autoDetectMarkdown: Bool {
        didSet { UserDefaults.standard.set(autoDetectMarkdown, forKey: Keys.autoDetect) }
    }

    @Published var playSound: Bool {
        didSet { UserDefaults.standard.set(playSound, forKey: Keys.sound) }
    }

    @Published var showNotification: Bool {
        didSet { UserDefaults.standard.set(showNotification, forKey: Keys.notification) }
    }

    @Published var showPreview: Bool {
        didSet { UserDefaults.standard.set(showPreview, forKey: Keys.preview) }
    }

    var shortcutLabel: String { "⌥⌘C" }

    var launchAtLogin: Bool {
        get { LaunchAtLoginManager.shared.isEnabled }
        set { newValue ? LaunchAtLoginManager.shared.enable() : LaunchAtLoginManager.shared.disable() }
    }

    private enum Keys {
        static let autoDetect   = "cf_autoDetectMarkdown"
        static let sound        = "cf_playSound"
        static let notification = "cf_showNotification"
        static let preview      = "cf_showPreview"
    }

    private init() {
        UserDefaults.standard.register(defaults: [
            Keys.autoDetect:   true,
            Keys.sound:        true,
            Keys.notification: true,
            Keys.preview:      false,
        ])
        self.autoDetectMarkdown = UserDefaults.standard.bool(forKey: Keys.autoDetect)
        self.playSound          = UserDefaults.standard.bool(forKey: Keys.sound)
        self.showNotification   = UserDefaults.standard.bool(forKey: Keys.notification)
        self.showPreview        = UserDefaults.standard.bool(forKey: Keys.preview)
    }
}
