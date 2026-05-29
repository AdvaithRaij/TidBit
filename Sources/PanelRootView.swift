import AppKit
import SwiftUI
import UniformTypeIdentifiers

// FastTooltip removed. Native .help is preferred for production.

private enum TidbitSection: String, CaseIterable, Identifiable {
    case todos
    case clipboard

    var id: String { rawValue }
}

private enum TodoFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case done

    var id: String { rawValue }
}

fileprivate struct TidbitTheme {
    let theme: AppTheme
    let colorScheme: ColorScheme?

    var isDark: Bool {
        switch theme {
        case .light: return false
        case .dark: return true
        case .auto: return colorScheme == .dark
        }
    }

    var ink: Color {
        isDark ? Color(red: 0.95, green: 0.95, blue: 0.97) : Color(red: 0.22, green: 0.21, blue: 0.30)
    }

    var muted: Color {
        isDark ? Color(red: 0.65, green: 0.65, blue: 0.70) : Color(red: 0.46, green: 0.45, blue: 0.58)
    }

    var lavender: Color {
        isDark ? Color(red: 0.52, green: 0.48, blue: 0.76) : Color(red: 0.82, green: 0.78, blue: 0.96)
    }

    var sky: Color {
        isDark ? Color(red: 0.39, green: 0.59, blue: 0.78) : Color(red: 0.79, green: 0.89, blue: 0.98)
    }

    var mint: Color {
        isDark ? Color(red: 0.48, green: 0.72, blue: 0.64) : Color(red: 0.78, green: 0.92, blue: 0.84)
    }

    var rose: Color {
        isDark ? Color(red: 0.85, green: 0.51, blue: 0.54) : Color(red: 0.95, green: 0.81, blue: 0.84)
    }

    var line: Color {
        isDark ? Color.gray.opacity(0.30) : Color.gray.opacity(0.46)
    }

    var glass: Color {
        isDark ? Color.white.opacity(0.10) : Color.white.opacity(0.20)
    }

    var glassStrong: Color {
        isDark ? Color.white.opacity(0.20) : Color.white.opacity(0.34)
    }

    var background: Color {
        isDark ? Color(red: 0.15, green: 0.15, blue: 0.20) : Color(red: 0.96, green: 0.95, blue: 0.98)
    }
}

struct PanelRootView: View {
    @ObservedObject var appState: AppState
    let panelManager: DockPanelManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var draftText = ""
    @State private var draftImagePath: String?
    @State private var activeSection: TidbitSection = .todos
    @State private var todoFilter: TodoFilter = .all
    @State private var toastMessage: String?
    @State private var isHoveringDropZone = false
    @State private var clipboardSearchText = ""
    @State private var composerHeight: CGFloat = 48

    private var theme: TidbitTheme {
        TidbitTheme(theme: appState.theme, colorScheme: colorScheme)
    }

    private var filteredTodos: [TodoItem] {
        appState.items.filter { item in
            switch todoFilter {
            case .all:
                return true
            case .pending:
                return item.isChecked == false
            case .done:
                return item.isChecked
            }
        }
    }

    private var filteredClipboardItems: [ClipboardItem] {
        let trimmed = clipboardSearchText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Only search if 2+ characters
        guard trimmed.count >= 2 else {
            return appState.clipboardItems
        }

        // Filter and sort by relevance (only text items, skip images)
        let searchLower = trimmed.lowercased()
        return appState.clipboardItems
            .filter { item in
                // Don't index images
                guard item.kind != .image else { return false }
                return item.body.lowercased().contains(searchLower) ||
                       item.title.lowercased().contains(searchLower)
            }
            .sorted { item1, item2 in
                // Prioritize title matches over body matches
                let title1Match = item1.title.lowercased().contains(searchLower)
                let title2Match = item2.title.lowercased().contains(searchLower)
                if title1Match != title2Match {
                    return title1Match
                }

                // Then prioritize earlier occurrence in text
                let body1Lower = item1.body.lowercased()
                let body2Lower = item2.body.lowercased()
                if let index1 = body1Lower.range(of: searchLower)?.lowerBound,
                   let index2 = body2Lower.range(of: searchLower)?.lowerBound {
                    return index1 < index2
                }

                return false
            }
    }

    var body: some View {
        ZStack {
            theme.background
                .overlay(
                    LinearGradient(
                        colors: theme.isDark ? [
                            Color.blue.opacity(0.05),
                            Color.green.opacity(0.04),
                            Color.purple.opacity(0.05)
                        ] : [
                            Color(red: 0.86, green: 0.94, blue: 0.98).opacity(0.70),
                            Color(red: 0.87, green: 0.96, blue: 0.92).opacity(0.62),
                            Color(red: 0.96, green: 0.92, blue: 0.86).opacity(0.66)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 0) {
                header
                composer
                sectionBar
                content
                footer
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(theme.line.opacity(0.9), lineWidth: 1.4)
                .allowsHitTesting(false)
        )
        .overlay(resizeGuides)
        .background(.ultraThinMaterial.opacity(0.70))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 10)
        .overlay(alignment: .topTrailing) {
            if let toastMessage {
                Text(toastMessage)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(theme.sky.opacity(0.95), in: Capsule())
                    .padding(12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if isHoveringDropZone {
                Label("Drop to attach", systemImage: "paperclip")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(theme.glassStrong, in: Capsule())
                    .padding(12)
            }
        }
        .onDrop(of: [.fileURL, .image, .plainText, .url], isTargeted: $isHoveringDropZone, perform: handleDrop)
        .frame(minWidth: 270, minHeight: 320)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("Tidbit")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(theme.ink)

            Spacer()

            RepositionHandle(panelManager: panelManager)

            HeaderControl(symbol: appState.autoHideEnabled ? "pin.slash" : "pin", action: {
                panelManager.toggleAutoHide()
            }, theme: theme)

            HeaderControl(symbol: "xmark.circle", action: {
                NSApp.terminate(nil)
            }, theme: theme)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(theme.glass.opacity(0.25))
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if activeSection == .todos {
                HStack(spacing: 8) {
                    ZStack(alignment: .topLeading) {
                        if draftText.isEmpty {
                            Text("Add a todo or note. Press Enter to save.")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(theme.muted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $draftText)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.ink)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .padding(.trailing, 32)
                            .onChange(of: draftText) {
                                updateComposerHeight()
                            }

                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: importDraftImage) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(theme.muted)
                                }
                                .buttonStyle(.plain)
                                .cursor(.pointingHand)
                                .padding(8)
                            }
                        }
                    }
                    .frame(height: composerHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(theme.glassStrong)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(theme.line.opacity(0.35), lineWidth: 1)
                    )

                    Button(action: submitDraft) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(theme.ink)
                            .frame(width: 30, height: 30)
                            .background(theme.lavender.opacity(0.95), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .cursor(.pointingHand)
                }

                if let draftImagePath, let image = NSImage(contentsOfFile: draftImagePath) {
                    HStack(spacing: 8) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                        Text("Image attached")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.muted)

                        Spacer()

                        Button {
                            self.draftImagePath = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(theme.muted)
                        }
                        .buttonStyle(.plain)
                        .cursor(.pointingHand)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(theme.glassStrong, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            } else {
                // Search bar for clipboard
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.muted)

                    ZStack(alignment: .leading) {
                        if clipboardSearchText.isEmpty {
                            Text("Search clipboard")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(theme.muted)
                                .allowsHitTesting(false)
                        }

                        TextField("", text: $clipboardSearchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.ink)
                    }

                    if !clipboardSearchText.isEmpty {
                        Button {
                            clipboardSearchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(theme.muted.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .cursor(.pointingHand)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(theme.glassStrong)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(theme.line.opacity(0.35), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var sectionBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(TidbitSection.allCases) { section in
                    Button {
                        activeSection = section
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: section == .todos ? "checklist" : "doc.on.clipboard")
                            Text(section == .todos ? "Todos" : "Clipboard")
                        }
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(activeSection == section ? theme.ink : theme.muted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            Capsule(style: .continuous)
                                .fill(activeSection == section ? theme.glassStrong : theme.glass.opacity(0.6))
                        )
                    }
                    .buttonStyle(.plain)
                    .cursor(.pointingHand)
                }

                Spacer()
            }

            if activeSection == .todos {
                HStack(spacing: 8) {
                    ForEach(TodoFilter.allCases) { filter in
                        Button {
                            todoFilter = filter
                        } label: {
                            Text(filter.rawValue.capitalized)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(todoFilter == filter ? theme.ink : theme.muted)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(todoFilter == filter ? theme.glassStrong : theme.glass.opacity(0.6))
                                )
                        }
                        .buttonStyle(.plain)
                        .cursor(.pointingHand)
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var content: some View {
        if activeSection == .todos {
            ScrollView {
                LazyVStack(spacing: 8) {
                    if filteredTodos.isEmpty {
                        EmptyStateCard(title: "No matching todos", message: "Add one with Enter or attach an image.", theme: theme)
                    } else {
                        ForEach(Array(filteredTodos.enumerated()), id: \.element.id) { index, item in
                            TodoRow(
                                item: item,
                                onSaveEdit: { text in appState.updateTodo(item, text: text) },
                                onToggle: { appState.toggleCheck(for: item) },
                                onDelete: { appState.delete(item: item) },
                                onMoveUp: { appState.moveUp(item: item) },
                                onMoveDown: { appState.moveDown(item: item) },
                                canMoveUp: index > 0,
                                canMoveDown: index < filteredTodos.count - 1,
                                theme: theme
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    if appState.clipboardItems.isEmpty {
                        EmptyStateCard(title: "Clipboard is empty", message: "Recent copies will appear here.", theme: theme)
                    } else if filteredClipboardItems.isEmpty && clipboardSearchText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 {
                        EmptyStateCard(title: "No results", message: "No clipboard items match your search.", theme: theme)
                    } else {
                        ForEach(filteredClipboardItems) { item in
                            ClipboardRow(
                                item: item,
                                onCopy: {
                                    appState.copyClipboardItem(item)
                                    showToast("Copied!")
                                },
                                onDelete: { appState.deleteClipboardItem(item) },
                                theme: theme
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text(activeSection == .todos ? "\(filteredTodos.count) shown" : "\(filteredClipboardItems.count) clips")
                .foregroundStyle(theme.muted)

            Spacer()

            if activeSection == .todos {
                Button("Clear done") {
                    appState.clearDoneTodos()
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.muted)
                .cursor(.pointingHand)
            } else {
                Button("Clear clips") {
                    appState.clearClipboardHistory()
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.muted)
                .cursor(.pointingHand)
            }
        }
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(theme.glass.opacity(0.22))
    }

    private var resizeGuides: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(theme.line.opacity(0.85), lineWidth: 8)
            .padding(2)
            .allowsHitTesting(false)
    }

    private func submitDraft() {
        appState.addTodoDraft(text: draftText, imagePath: draftImagePath)
        draftText = ""
        draftImagePath = nil
        composerHeight = 48
    }

    private func updateComposerHeight() {
        let minHeight: CGFloat = 48
        let maxHeight: CGFloat = 120

        let lineHeight: CGFloat = 20
        let padding: CGFloat = 20
        let lines = max(1, draftText.split(separator: "\n").count)
        let calculatedHeight = CGFloat(lines) * lineHeight + padding

        composerHeight = min(max(calculatedHeight, minHeight), maxHeight)
    }

    private func importDraftImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url, let imagePath = appState.importImageForDraft(from: url) {
            draftImagePath = imagePath
            showToast("Image attached")
        }
    }



    private func showToast(_ message: String) {
        withAnimation(.easeInOut(duration: 0.18)) {
            toastMessage = message
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.18)) {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }



    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    let fileURL: URL?

                    if let data = item as? Data {
                        fileURL = URL(dataRepresentation: data, relativeTo: nil)
                    } else if let url = item as? URL {
                        fileURL = url
                    } else if let url = item as? NSURL {
                        fileURL = url as URL
                    } else {
                        fileURL = nil
                    }

                    guard let fileURL else { return }

                    Task { @MainActor in
                        if let imagePath = appState.importImageForDraft(from: fileURL) {
                            draftImagePath = imagePath
                            showToast("Image attached")
                        } else {
                            draftText = fileURL.absoluteString
                        }
                    }
                }
                return true
            }

            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        Task { @MainActor in
                            draftText = url.absoluteString
                        }
                    } else if let url = item as? URL {
                        Task { @MainActor in
                            draftText = url.absoluteString
                        }
                    }
                }
                return true
            }

            if provider.canLoadObject(ofClass: NSString.self) {
                provider.loadObject(ofClass: NSString.self) { item, _ in
                    guard let text = item as? String else { return }
                    Task { @MainActor in
                        draftText = text
                    }
                }
                return true
            }
        }

        return false
    }
}

private struct HeaderControl: View {
    let symbol: String
    let action: () -> Void
    let theme: TidbitTheme

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(theme.muted)
                .frame(width: 28, height: 28)
                .background(theme.glassStrong, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .cursor(.pointingHand)
    }
}

private struct TodoRow: View {
    let item: TodoItem
    let onSaveEdit: (String) -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let canMoveUp: Bool
    let canMoveDown: Bool
    let theme: TidbitTheme

    @State private var isEditing = false
    @State private var draftText = ""
    @State private var isHovering = false
    @State private var showFullContent = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(item.isChecked ? theme.mint : theme.line, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if item.isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(theme.ink)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onToggle()
                }

                if isEditing {
                    ZStack(alignment: .bottomTrailing) {
                        InlineEditView(text: $draftText, theme: theme)
                            .frame(minHeight: 80, maxHeight: 140)
                            .background(theme.glassStrong)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(theme.lavender.opacity(0.6), lineWidth: 2)
                            )

                        HStack(spacing: 6) {
                            Button(action: {
                                let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else {
                                    draftText = item.body
                                    isEditing = false
                                    return
                                }
                                onSaveEdit(draftText)
                                isEditing = false
                            }) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(theme.ink)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 24, height: 24)
                            .background(theme.glassStrong, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .contentShape(Rectangle())
                            .onHover { inside in
                                if inside {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }

                            Button(action: {
                                draftText = item.body
                                isEditing = false
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(theme.ink)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 24, height: 24)
                            .background(theme.glassStrong, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .contentShape(Rectangle())
                            .onHover { inside in
                                if inside {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                        .padding(8)
                        .background(Color.clear)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 5) {
                            if let imagePath = item.imagePath, let image = NSImage(contentsOfFile: imagePath) {
                                // Layout with image
                                HStack(alignment: .top, spacing: 10) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.title.isEmpty ? "Untitled note" : item.title)
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundStyle(item.isChecked ? theme.muted : theme.ink)
                                            .strikethrough(item.isChecked, color: theme.ink)
                                            .opacity(item.isChecked ? 0.65 : 1)
                                            .lineLimit(2)
                                            .help(item.title)

                                        if item.body.isEmpty == false {
                                            Text(previewText)
                                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                                .foregroundStyle(item.isChecked ? theme.muted.opacity(0.75) : theme.muted)
                                                .strikethrough(item.isChecked, color: theme.muted)
                                                .lineLimit(2)
                                                .help(item.body)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture(count: 2) {
                                        draftText = item.body
                                        isEditing = true
                                    }

                                    Spacer()

                                    VStack(spacing: 4) {
                                        Image(nsImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                                        Text(relativeAddedText(from: item.createdAt))
                                            .font(.system(size: 9, weight: .medium, design: .rounded))
                                            .foregroundStyle(theme.muted.opacity(0.85))
                                    }
                                }
                            } else {
                                // Layout without image
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title.isEmpty ? "Untitled note" : item.title)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundStyle(item.isChecked ? theme.muted : theme.ink)
                                        .strikethrough(item.isChecked, color: theme.ink)
                                        .opacity(item.isChecked ? 0.65 : 1)
                                        .lineLimit(2)
                                        .help(item.title)

                                    if item.body.isEmpty == false {
                                        Text(previewText)
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                            .foregroundStyle(item.isChecked ? theme.muted.opacity(0.75) : theme.muted)
                                            .strikethrough(item.isChecked, color: theme.muted)
                                            .lineLimit(2)
                                            .help(item.body)
                                    }

                                    Text(relativeAddedText(from: item.createdAt))
                                        .font(.system(size: 9, weight: .medium, design: .rounded))
                                        .foregroundStyle(theme.muted.opacity(0.85))
                                }
                                .contentShape(Rectangle())
                                .onTapGesture(count: 2) {
                                    draftText = item.body
                                    isEditing = true
                                }
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 16) {
                        Button(action: onDelete) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(theme.muted.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                        .cursor(.pointingHand)

                        VStack(spacing: 4) {
                            Button(action: onMoveUp) {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(canMoveUp ? theme.muted : theme.muted.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                            .cursor(.pointingHand)
                            .disabled(!canMoveUp)

                            Button(action: onMoveDown) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(canMoveDown ? theme.muted : theme.muted.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                            .cursor(.pointingHand)
                            .disabled(!canMoveDown)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isHovering ? theme.glass.opacity(0.35) : theme.glass.opacity(0.15))
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var previewText: String {
        String(item.body.prefix(50))
    }

    private func relativeAddedText(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Added " + formatter.localizedString(for: date, relativeTo: .now)
    }
}

private struct ClipboardRow: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onDelete: () -> Void
    let theme: TidbitTheme

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if item.kind == .image, let image = NSImage(contentsOfFile: item.body) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.muted)
                    .frame(width: 18, height: 18)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.ink)
                    .lineLimit(2)
                    .help(item.title)

                Text(preview)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.muted)
                    .lineLimit(2)
                    .help(item.body)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(theme.muted.opacity(0.5))
            }
            .buttonStyle(.plain)
            .cursor(.pointingHand)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isHovering ? theme.glass.opacity(0.35) : theme.glass.opacity(0.15))
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onCopy()
        }
    }

    private var symbol: String {
        switch item.kind {
        case .text: return "text.alignleft"
        case .url: return "link"
        case .image: return "photo"
        }
    }

    private var preview: String {
        switch item.kind {
        case .text, .url:
            return item.body
        case .image:
            return "Image clip"
        }
    }
}

private struct EmptyStateCard: View {
    let title: String
    let message: String
    let theme: TidbitTheme

    var body: some View{
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(theme.ink)
            Text(message)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(theme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.glassStrong)
        )
    }
}

private struct InlineEditView: View {
    @Binding var text: String
    let theme: TidbitTheme
    @FocusState private var isFocused: Bool

    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(theme.ink)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .padding(6)
            .focused($isFocused)
            .onAppear {
                isFocused = true
            }
    }
}



private struct RepositionHandle: NSViewRepresentable {
    let panelManager: DockPanelManager

    func makeNSView(context: Context) -> RepositionHandleView {
        let view = RepositionHandleView()
        view.panelManager = panelManager
        return view
    }

    func updateNSView(_ nsView: RepositionHandleView, context: Context) {
        nsView.panelManager = panelManager
    }
}

final class RepositionHandleView: NSView {
    weak var panelManager: DockPanelManager?
    private let imageView = NSImageView()
    private var trackingArea: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: NSRect(x: 0, y: 0, width: 28, height: 28))
        wantsLayer = true
        layer?.cornerRadius = 8

        // Use a semi-transparent dark background that's visible in both themes
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.25).cgColor

        imageView.image = NSImage(systemSymbolName: "arrow.left.and.right", accessibilityDescription: "Reposition")
        imageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        imageView.contentTintColor = NSColor.white.withAlphaComponent(0.8)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 28),
            heightAnchor.constraint(equalToConstant: 28),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        setupTrackingArea()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTrackingArea() {
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        setupTrackingArea()
    }

    override func mouseEntered(with event: NSEvent) {
        NSCursor.openHand.push()
    }

    override func mouseExited(with event: NSEvent) {
        NSCursor.pop()
    }

    override func mouseDown(with event: NSEvent) {
        NSCursor.closedHand.push()
        panelManager?.beginRepositioning()
        window?.performDrag(with: event)
        NSCursor.pop()
    }
}

// MARK: - SwiftUI Extensions
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
