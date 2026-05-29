import AppKit

@MainActor
final class StatusBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()

    private let togglePinAction: () -> Void
    private let clipboardAction: () -> Void
    private let preferencesAction: () -> Void

    init(
        togglePinAction: @escaping () -> Void,
        clipboardAction: @escaping () -> Void,
        preferencesAction: @escaping () -> Void
    ) {
        self.togglePinAction = togglePinAction
        self.clipboardAction = clipboardAction
        self.preferencesAction = preferencesAction
        super.init()
        configure()
    }

    private func configure() {
        statusItem.length = NSStatusItem.squareLength
        statusItem.isVisible = true

        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "Tidbit") ??
                           NSImage(systemSymbolName: "list.bullet", accessibilityDescription: "Tidbit") ??
                           NSImage(systemSymbolName: "checkmark.square", accessibilityDescription: "Tidbit") {
                image.isTemplate = true
                button.image = image
                button.imagePosition = .imageOnly
            }
            button.title = ""
            button.toolTip = "Tidbit"
        }

        let pin = NSMenuItem(title: "Pin Tidbit", action: #selector(togglePin), keyEquivalent: "")
        let clipboard = NSMenuItem(title: "Capture Clipboard Now", action: #selector(captureClipboard), keyEquivalent: "")
        let preferences = NSMenuItem(title: "Preferences", action: #selector(openPreferences), keyEquivalent: "")
        let quit = NSMenuItem(title: "Quit Tidbit", action: #selector(quitApp), keyEquivalent: "q")

        [pin, clipboard, preferences, quit].forEach {
            $0.target = self
            menu.addItem($0)
        }
        menu.insertItem(.separator(), at: 2)
        statusItem.menu = menu
    }

    @objc private func togglePin() {
        togglePinAction()
    }

    @objc private func captureClipboard() {
        clipboardAction()
    }

    @objc private func openPreferences() {
        preferencesAction()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
