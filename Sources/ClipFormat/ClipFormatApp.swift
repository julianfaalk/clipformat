import SwiftUI

@main
struct ClipFormatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        // No window — pure menu bar app
        Settings {
            EmptyView()
        }
    }
}
