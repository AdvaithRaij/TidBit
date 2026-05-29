import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    init(appState: AppState) {
        let view = SettingsView(appState: appState)
        let hostingController = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Tidbit Preferences"
        window.setContentSize(NSSize(width: 400, height: 300))
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.titlebarAppearsTransparent = true
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.center()
        window?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct SettingsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Tidbit Preferences")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            VStack(alignment: .leading, spacing: 14) {
                Toggle("Auto-hide when docked to the screen edge", isOn: Binding(
                    get: { appState.autoHideEnabled },
                    set: { newValue in
                        appState.autoHideEnabled = newValue
                        appState.persist()
                    }
                ))

                HStack {
                    Text("Theme")
                    Spacer()
                    Picker("", selection: Binding(
                        get: { appState.theme },
                        set: { newValue in
                            appState.theme = newValue
                            appState.persist()
                        }
                    )) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .frame(width: 160)
                }

                HStack {
                    Text("Dock edge side")
                    Spacer()
                    Picker("", selection: Binding(
                        get: { appState.dockEdge },
                        set: { newValue in
                            appState.dockEdge = newValue
                            appState.persist()
                        }
                    )) {
                        ForEach(DockEdge.allCases) { edge in
                            Text(edge.rawValue.capitalized).tag(edge)
                        }
                    }
                    .frame(width: 100)
                }
            }
            .font(.system(size: 13, weight: .medium, design: .rounded))

            Spacer()

            Text("Tip: The panel will automatically snap to the nearest side (left or right) when repositioning.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
