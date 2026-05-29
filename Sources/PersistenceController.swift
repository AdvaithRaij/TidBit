import Foundation

struct PersistenceController {
    private let fileManager = FileManager.default
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func load() -> StoredState {
        guard
            let url = stateURL,
            let data = try? Data(contentsOf: url),
            let state = try? decoder.decode(StoredState.self, from: data)
        else {
            return .default
        }

        return state
    }

    func save(_ state: StoredState) {
        guard let url = stateURL else { return }

        do {
            try createDirectoriesIfNeeded()
            let data = try encoder.encode(state)
            try data.write(to: url, options: .atomic)
        } catch {
            NSLog("Failed to save state: \(error.localizedDescription)")
        }
    }

    func copyImageToLibrary(from sourceURL: URL) -> URL? {
        guard let attachmentsURL else { return nil }

        do {
            try createDirectoriesIfNeeded()
            let ext = sourceURL.pathExtension.isEmpty ? "png" : sourceURL.pathExtension
            let destination = attachmentsURL.appendingPathComponent("\(UUID().uuidString).\(ext)")
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: sourceURL, to: destination)
            return destination
        } catch {
            NSLog("Failed to import image: \(error.localizedDescription)")
            return nil
        }
    }

    func writePastedImage(data: Data) -> URL? {
        guard let attachmentsURL else { return nil }

        do {
            try createDirectoriesIfNeeded()
            let destination = attachmentsURL.appendingPathComponent("\(UUID().uuidString).png")
            try data.write(to: destination, options: .atomic)
            return destination
        } catch {
            NSLog("Failed to write pasted image: \(error.localizedDescription)")
            return nil
        }
    }

    private var baseDirectory: URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Tidbit", isDirectory: true)
    }

    private var stateURL: URL? {
        baseDirectory?.appendingPathComponent("state.json")
    }

    private var attachmentsURL: URL? {
        baseDirectory?.appendingPathComponent("Attachments", isDirectory: true)
    }

    private func createDirectoriesIfNeeded() throws {
        guard let baseDirectory, let attachmentsURL else { return }
        try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: attachmentsURL, withIntermediateDirectories: true)
    }
}
