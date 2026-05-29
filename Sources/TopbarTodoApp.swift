import SwiftUI

@main
struct TopbarTodoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // StatusBarController handles the menu bar icon now
        Settings {
            EmptyView()
        }
    }
}
