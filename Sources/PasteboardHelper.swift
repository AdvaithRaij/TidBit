import AppKit

enum PasteboardContent {
    case imageURL(URL)
    case imageData(Data)
    case url(String)
    case text(String)
    case none
}

@MainActor
enum PasteboardHelper {
    static func extractContent(from pasteboard: NSPasteboard = .general) -> PasteboardContent {
        if pasteboard.canReadObject(forClasses: [NSURL.self], options: nil),
           let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let firstURL = urls.first {
            if NSImage(contentsOf: firstURL) != nil {
                return .imageURL(firstURL)
            } else {
                return .url(firstURL.absoluteString)
            }
        }

        if let image = NSImage(pasteboard: pasteboard),
           let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            return .imageData(pngData)
        }

        if let string = pasteboard.string(forType: .string) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return .none }
            
            if let url = URL(string: trimmed), url.scheme != nil {
                return .url(url.absoluteString)
            } else {
                return .text(trimmed)
            }
        }

        return .none
    }
}
