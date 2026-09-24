import AppKit
import Combine
import Foundation
import UniformTypeIdentifiers

@MainActor
final class AppState: ObservableObject {
    @Published var items: [TodoItem]
    @Published var clipboardItems: [ClipboardItem]
    @Published var dockEdge: DockEdge
    @Published var edgeRatio: Double
    @Published var panelSize: CGSize
    @Published var autoHideEnabled: Bool
    @Published var theme: AppTheme
    @Published var hotkey: String

    private let persistence = PersistenceController()
    private var pasteboardChangeCount: Int
    private var clipboardMonitor: Timer?

    init() {
        let state = persistence.load()
        items = state.items
        clipboardItems = state.clipboardItems
        dockEdge = state.dockEdge
        edgeRatio = state.edgeRatio
        panelSize = CGSize(width: state.panelSize.width, height: state.panelSize.height)
        autoHideEnabled = state.autoHideEnabled
        theme = state.theme
        hotkey = state.hotkey
        pasteboardChangeCount = NSPasteboard.general.changeCount
        startClipboardMonitor()
    }

    func persist() {
        persistence.save(
            StoredState(
                items: items,
                clipboardItems: clipboardItems,
                dockEdge: dockEdge,
                edgeRatio: edgeRatio,
                panelSize: StoredSize(width: panelSize.width, height: panelSize.height),
                autoHideEnabled: autoHideEnabled,
                theme: theme,
                hotkey: hotkey
            )
        )
    }

    func addText(_ text: String) {
        addTodo(text: text, imagePath: nil)
    }

    func addTodo(text: String, imagePath: String?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || imagePath != nil else { return }

        let title = trimmed
            .split(separator: "\n", maxSplits: 1)
            .first
            .map(String.init) ?? (imagePath != nil ? "Image note" : trimmed)

        items.insert(
            TodoItem(
                kind: imagePath == nil ? .text : .image,
                title: title,
                body: trimmed,
                imagePath: imagePath
            ),
            at: 0
        )
        persist()
    }

    func addTodoFromInput(_ text: String) {
        addTodoDraft(text: text, imagePath: nil)
    }

    func addTodoDraft(text: String, imagePath: String?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let url = URL(string: trimmed), url.scheme != nil, imagePath == nil {
            addURL(trimmed)
        } else {
            addTodo(text: trimmed, imagePath: imagePath)
        }
    }

    func addURL(_ rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme != nil else { return }

        items.insert(
            TodoItem(kind: .url, title: url.host ?? trimmed, body: url.absoluteString),
            at: 0
        )
        persist()
    }

    func addImage(from sourceURL: URL) {
        guard let copiedURL = persistence.copyImageToLibrary(from: sourceURL) else { return }
        items.insert(
            TodoItem(kind: .image, title: copiedURL.lastPathComponent, body: "", imagePath: copiedURL.path),
            at: 0
        )
        persist()
    }

    func importImageForDraft(from sourceURL: URL) -> String? {
        persistence.copyImageToLibrary(from: sourceURL)?.path
    }

    func copyClipboardItem(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.kind {
        case .text, .url:
            pasteboard.setString(item.body, forType: .string)
        case .image:
            if let image = NSImage(contentsOfFile: item.body) {
                pasteboard.writeObjects([image])
            }
        }
    }

    func deleteClipboardItem(_ item: ClipboardItem) {
        clipboardItems.removeAll { $0.id == item.id }
        persist()
    }

    func clearClipboardHistory() {
        clipboardItems.removeAll()
        persist()
    }

    func toggleCheck(for item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = items[index]
        updated.isChecked.toggle()
        items.remove(at: index)
        if updated.isChecked {
            items.append(updated)
        } else {
            let firstDoneIndex = items.firstIndex(where: { $0.isChecked }) ?? items.endIndex
            items.insert(updated, at: firstDoneIndex)
        }
        objectWillChange.send()
        persist()
    }

    func updateTodo(_ item: TodoItem, text: String) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmed.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? item.title

        var updated = items[index]
        updated.title = title.isEmpty ? item.title : title
        updated.body = trimmed
        updated.kind = updated.imagePath == nil ? (URL(string: trimmed)?.scheme != nil ? .url : .text) : .image
        items[index] = updated
        objectWillChange.send()
        persist()
    }

    func delete(item: TodoItem) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    func applyOrder(_ orderedVisible: [TodoItem]) {
        let visibleIds = Set(orderedVisible.map { $0.id })
        let positions = items.indices.filter { visibleIds.contains(items[$0].id) }
        var newItems = items
        for (pos, item) in zip(positions, orderedVisible) {
            newItems[pos] = item
        }
        items = newItems
        persist()
    }

    func clearAll() {
        items.removeAll()
        persist()
    }

    func clearDoneTodos() {
        items.removeAll { $0.isChecked }
        persist()
    }

    func captureCurrentClipboardIfNeeded(force: Bool = false) {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        if force == false, currentChangeCount == pasteboardChangeCount {
            return
        }

        pasteboardChangeCount = currentChangeCount

        let content = PasteboardHelper.extractContent(from: pasteboard)
        switch content {
        case .imageURL(let url):
            let sourceKey = url.absoluteString
            if let idx = clipboardItems.firstIndex(where: { $0.kind == .image && $0.sourceKey == sourceKey }) {
                if idx != 0 {
                    let existing = clipboardItems.remove(at: idx)
                    clipboardItems.insert(existing, at: 0)
                    persist()
                }
                return
            }
            guard let copiedURL = persistence.copyImageToLibrary(from: url) else { return }
            storeClipboardItem(ClipboardItem(kind: .image, title: copiedURL.lastPathComponent, body: copiedURL.path, sourceKey: sourceKey))
        case .imageData(let data):
            let roughHash = data.prefix(256).reduce(0 as UInt64) { $0 ^ UInt64($1) }
            let sourceKey = "data_\(data.count)_\(roughHash)"
            if let idx = clipboardItems.firstIndex(where: { $0.kind == .image && $0.sourceKey == sourceKey }) {
                if idx != 0 {
                    let existing = clipboardItems.remove(at: idx)
                    clipboardItems.insert(existing, at: 0)
                    persist()
                }
                return
            }
            guard let url = persistence.writePastedImage(data: data) else { return }
            storeClipboardItem(ClipboardItem(kind: .image, title: url.lastPathComponent, body: url.path, sourceKey: sourceKey))
        case .url(let urlString):
            let title = URL(string: urlString)?.host ?? urlString
            storeClipboardItem(ClipboardItem(kind: .url, title: title, body: urlString))
        case .text(let text):
            let title = text.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? text
            storeClipboardItem(ClipboardItem(kind: .text, title: title, body: text))
        case .none:
            break
        }
    }

    private func startClipboardMonitor() {
        clipboardMonitor = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.captureCurrentClipboardIfNeeded()
            }
        }
    }

    private func storeClipboardItem(_ item: ClipboardItem) {
        if let existingIndex = clipboardItems.firstIndex(where: { $0.kind == item.kind && $0.body == item.body }) {
            clipboardItems.remove(at: existingIndex)
        }

        clipboardItems.insert(item, at: 0)
        if clipboardItems.count > 20 {
            clipboardItems = Array(clipboardItems.prefix(20))
        }
        persist()
    }
}
