import ServiceManagement
import Foundation

/// Manages "Launch at Login" via SMAppService (macOS 13+).
final class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()
    private init() {}

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func enable() {
        do {
            try SMAppService.mainApp.register()
        } catch {
            print("ClipFormat: Launch at login enable failed: \(error)")
        }
    }

    func disable() {
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            print("ClipFormat: Launch at login disable failed: \(error)")
        }
    }

    func toggle() {
        isEnabled ? disable() : enable()
    }
}
