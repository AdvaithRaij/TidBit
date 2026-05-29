import AppKit
import SwiftUI

@MainActor
final class DockPanelManager: NSObject, NSWindowDelegate {
    private let appState: AppState
    private let panel: DockPanel
    private var workspaceObserver: NSObjectProtocol?
    private var screenObserver: NSObjectProtocol?

    private var hoverView: HoverTrackingView?
    private var isHiddenToEdge = false
    private var isRepositioning = false
    private var isPointerInside = false
    private var isAnimatingLayout = false
    private var pendingHideWorkItem: DispatchWorkItem?
    private var snapWorkItem: DispatchWorkItem?

    private let tabThickness: CGFloat = 26
    private let margin: CGFloat = 8

    init(appState: AppState) {
        self.appState = appState
        panel = DockPanel(
            contentRect: CGRect(origin: .zero, size: appState.panelSize),
            styleMask: [.borderless, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        super.init()
        configurePanel()
        registerWorkspaceObservers()
    }

    func showInitialPosition() {
        panel.setFrame(frameForCurrentState(visible: true, screen: currentTargetScreen()), display: true)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        isHiddenToEdge = false
        if appState.autoHideEnabled {
            scheduleHideIfNeeded()
        }
    }

    func toggle() {
        if panel.isVisible == false {
            showExpanded()
            return
        }

        if isHiddenToEdge {
            showExpanded()
        } else if panel.isKeyWindow {
            panel.orderOut(nil)
        } else {
            showExpanded()
        }
    }

    func showExpanded(manual: Bool = true) {
        isHiddenToEdge = false
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        panel.alphaValue = 1.0
        animate(to: frameForCurrentState(visible: true, screen: currentTargetScreen()))
    }

    func beginRepositioning() {
        isRepositioning = true
        showExpanded(manual: false)
    }

    private func configurePanel() {
        panel.delegate = self
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.acceptsMouseMovedEvents = true
        panel.minSize = CGSize(width: 280, height: 320)

        let rootView = PanelRootView(appState: appState, panelManager: self)
        let hostingController = NSHostingController(rootView: rootView)

        let hoverView = HoverTrackingView(frame: CGRect(origin: .zero, size: appState.panelSize))
        hoverView.autoresizingMask = [.width, .height]
        hoverView.onHoverChanged = { [weak self] hovering in
            self?.handleHoverChange(isHovering: hovering)
        }

        hostingController.view.frame = hoverView.bounds
        hostingController.view.autoresizingMask = [.width, .height]
        hoverView.addSubview(hostingController.view)

        panel.contentView = hoverView
        self.hoverView = hoverView
    }

    private func handleHoverChange(isHovering: Bool) {
        isPointerInside = isHovering
        guard appState.autoHideEnabled, !isRepositioning else { return }

        if isHovering {
            pendingHideWorkItem?.cancel()
            showExpanded(manual: false)
        } else {
            scheduleHideIfNeeded()
        }
    }

    private func hideToEdge(animated: Bool) {
        guard appState.autoHideEnabled else { return }
        isHiddenToEdge = true
        panel.alphaValue = 0.3
        let target = frameForCurrentState(visible: false, screen: currentTargetScreen())
        if animated {
            animate(to: target)
        } else {
            panel.setFrame(target, display: true)
        }
    }

    private func animate(to frame: CGRect) {
        isAnimatingLayout = true
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
        } completionHandler: { [weak self] in
            self?.isAnimatingLayout = false
        }
    }

    private func scheduleHideIfNeeded() {
        pendingHideWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard self.appState.autoHideEnabled else { return }
            // Only check if pointer is inside tracked area, not nearby
            if self.isPointerInside {
                self.scheduleHideIfNeeded()
                return
            }
            self.hideToEdge(animated: true)
        }

        pendingHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }

    private func frameForCurrentState(visible: Bool, screen: NSScreen) -> CGRect {
        let visibleFrame = screen.visibleFrame
        let size = appState.panelSize

        let maxX = visibleFrame.maxX - size.width - margin
        let clampedRatio = min(max(appState.edgeRatio, 0), 1)

        switch appState.dockEdge {
        case .left:
            let y = visibleFrame.minY + (visibleFrame.height - size.height) * clampedRatio
            let x = visible ? visibleFrame.minX + margin : visibleFrame.minX - size.width + tabThickness
            return CGRect(x: x, y: y, width: size.width, height: size.height)

        case .right:
            let y = visibleFrame.minY + (visibleFrame.height - size.height) * clampedRatio
            let x = visible ? maxX : visibleFrame.maxX - tabThickness
            return CGRect(x: x, y: y, width: size.width, height: size.height)
        }
    }

    private func currentTargetScreen() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        if let mouseScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) {
            return mouseScreen
        }

        return panel.screen ?? NSScreen.main ?? NSScreen.screens[0]
    }

    private func pointerIsNearPanel() -> Bool {
        panel.frame.insetBy(dx: -16, dy: -16).contains(NSEvent.mouseLocation)
    }

    private func updateDockingStateFromCurrentFrame() {
        guard let screen = panel.screen ?? NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let frame = panel.frame

        // Only check left and right edges
        let distances: [(DockEdge, CGFloat)] = [
            (.left, abs(frame.minX - visibleFrame.minX)),
            (.right, abs(frame.maxX - visibleFrame.maxX))
        ]

        guard let nearest = distances.min(by: { $0.1 < $1.1 }) else { return }
        appState.dockEdge = nearest.0

        // Always calculate vertical position ratio
        let denominator = max(visibleFrame.height - frame.height, 1)
        appState.edgeRatio = (frame.minY - visibleFrame.minY) / denominator

        appState.edgeRatio = min(max(appState.edgeRatio, 0), 1)
        appState.panelSize = frame.size
        appState.persist()
    }

    private func registerWorkspaceObservers() {
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reanchorToCurrentScreen()
            }
        }

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reanchorToCurrentScreen()
            }
        }
    }

    private func reanchorToCurrentScreen() {
        guard panel.isVisible else { return }
        let targetScreen = currentTargetScreen()
        let targetFrame = frameForCurrentState(visible: !isHiddenToEdge, screen: targetScreen)
        panel.setFrame(targetFrame, display: true)
        panel.orderFrontRegardless()
    }

    func windowDidMove(_ notification: Notification) {
        panel.invalidateShadow()
        guard isRepositioning, !isAnimatingLayout else { return }

        snapWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.updateDockingStateFromCurrentFrame()
            self.isRepositioning = false
            if self.appState.autoHideEnabled, !self.isPointerInside {
                self.scheduleHideIfNeeded()
            }
        }
        snapWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    func windowDidResize(_ notification: Notification) {
        appState.panelSize = panel.frame.size
        appState.persist()
        if !isRepositioning {
            panel.setFrame(frameForCurrentState(visible: !isHiddenToEdge, screen: currentTargetScreen()), display: true)
        }
    }

    func windowDidBecomeKey(_ notification: Notification) {
        if isHiddenToEdge {
            showExpanded()
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        if appState.autoHideEnabled, !isPointerInside {
            scheduleHideIfNeeded()
        }
    }

    func toggleAutoHide() {
        appState.autoHideEnabled.toggle()
        appState.persist()

        if appState.autoHideEnabled, !isPointerInside {
            scheduleHideIfNeeded()
        } else {
            pendingHideWorkItem?.cancel()
            showExpanded()
        }
    }
}

final class DockPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown || event.type == .rightMouseDown {
            NSApp.activate(ignoringOtherApps: true)
            makeKeyAndOrderFront(nil)
        }
        super.sendEvent(event)
    }
}

final class HoverTrackingView: NSView {
    var onHoverChanged: ((Bool) -> Void)?
    private var trackingArea: NSTrackingArea?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        super.mouseDown(with: event)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        self.trackingArea = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        onHoverChanged?(true)
    }

    override func mouseExited(with event: NSEvent) {
        onHoverChanged?(false)
    }
}
