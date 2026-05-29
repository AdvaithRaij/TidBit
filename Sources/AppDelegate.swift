import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()

    private var panelManager: DockPanelManager?
    private var hotKeyMonitor: GlobalHotKeyMonitor?
    private var settingsController: SettingsWindowController?
    private var statusBarController: StatusBarController?
    private var menuBarObservers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Keep the core behavior enabled on startup even for existing saved state.
        if appState.autoHideEnabled == false {
            appState.autoHideEnabled = true
            appState.persist()
        }

        let settingsController = SettingsWindowController(appState: appState)
        let panelManager = DockPanelManager(appState: appState)

        hotKeyMonitor = GlobalHotKeyMonitor {
            panelManager.toggle()
        }

        // Create status bar icon
        let statusBarController = StatusBarController(
            togglePinAction: { panelManager.toggleAutoHide() },
            clipboardAction: { [weak self] in
                Task { @MainActor [weak self] in
                    self?.appState.captureCurrentClipboardIfNeeded(force: true)
                    panelManager.showExpanded()
                }
            },
            preferencesAction: { settingsController.showWindow(nil) }
        )

        registerMenuBarObservers(panelManager: panelManager, settingsController: settingsController)
        self.settingsController = settingsController
        self.panelManager = panelManager
        self.statusBarController = statusBarController
        panelManager.showInitialPosition()
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuBarObservers.forEach(NotificationCenter.default.removeObserver(_:))
        menuBarObservers.removeAll()
    }

    private func registerMenuBarObservers(panelManager: DockPanelManager, settingsController: SettingsWindowController) {
        let notificationCenter = NotificationCenter.default

        let toggleObserver = notificationCenter.addObserver(
            forName: .tidbitTogglePanel,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                panelManager.toggle()
            }
        }

        let repositionObserver = notificationCenter.addObserver(
            forName: .tidbitRepositionPanel,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                panelManager.beginRepositioning()
            }
        }

        let clipboardObserver = notificationCenter.addObserver(
            forName: .tidbitCaptureClipboard,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.appState.captureCurrentClipboardIfNeeded(force: true)
                panelManager.showExpanded()
            }
        }

        let preferencesObserver = notificationCenter.addObserver(
            forName: .tidbitOpenPreferences,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                settingsController.showWindow(nil)
            }
        }

        let quitObserver = notificationCenter.addObserver(
            forName: .tidbitQuit,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                NSApp.terminate(nil)
            }
        }

        menuBarObservers = [toggleObserver, repositionObserver, clipboardObserver, preferencesObserver, quitObserver]
    }
}

extension Notification.Name {
    static let tidbitTogglePanel = Notification.Name("tidbit.menu.togglePanel")
    static let tidbitRepositionPanel = Notification.Name("tidbit.menu.repositionPanel")
    static let tidbitCaptureClipboard = Notification.Name("tidbit.menu.captureClipboard")
    static let tidbitOpenPreferences = Notification.Name("tidbit.menu.openPreferences")
    static let tidbitQuit = Notification.Name("tidbit.menu.quit")
}
