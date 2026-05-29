import Foundation

enum TodoKind: String, Codable, CaseIterable, Identifiable {
    case text
    case url
    case image

    var id: String { rawValue }
}

struct ClipboardItem: Codable, Identifiable, Equatable {
    let id: UUID
    var kind: TodoKind
    var title: String
    var body: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        kind: TodoKind,
        title: String,
        body: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.createdAt = createdAt
    }
}

enum DockEdge: String, Codable, CaseIterable, Identifiable {
    case left
    case right

    var id: String { rawValue }
}

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case light
    case dark
    case auto

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .auto: return "Auto (System)"
        }
    }
}

struct StoredSize: Codable {
    var width: Double
    var height: Double
}

struct TodoItem: Codable, Identifiable, Equatable {
    let id: UUID
    var kind: TodoKind
    var title: String
    var body: String
    var imagePath: String?
    var createdAt: Date
    var isChecked: Bool

    init(
        id: UUID = UUID(),
        kind: TodoKind,
        title: String,
        body: String = "",
        imagePath: String? = nil,
        createdAt: Date = .now,
        isChecked: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.imagePath = imagePath
        self.createdAt = createdAt
        self.isChecked = isChecked
    }
}

struct StoredState: Codable {
    var items: [TodoItem]
    var clipboardItems: [ClipboardItem]
    var dockEdge: DockEdge
    var edgeRatio: Double
    var panelSize: StoredSize
    var autoHideEnabled: Bool
    var theme: AppTheme
    var hotkey: String

    static let `default` = StoredState(
        items: [],
        clipboardItems: [],
        dockEdge: .right,
        edgeRatio: 0.25,
        panelSize: StoredSize(width: 318, height: 456),
        autoHideEnabled: true,
        theme: .auto,
        hotkey: "⌥⌘C"
    )
}
