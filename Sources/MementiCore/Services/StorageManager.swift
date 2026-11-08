import Foundation
import Combine

public final class StorageManager: ObservableObject {
    public static let shared = StorageManager()

    @Published public private(set) var clips: [ClipItem] = []

    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.mementi.storage", qos: .utility)

    public init(customURL: URL? = nil) {
        if let customURL = customURL {
            self.fileURL = customURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let mementiDir = appSupport.appendingPathComponent("Mementi", isDirectory: true)
            try? FileManager.default.createDirectory(at: mementiDir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            self.fileURL = mementiDir.appendingPathComponent("clips.json")
        }
        load()
        pruneExpiredItems()
    }

    public func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            clips = []
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([ClipItem].self, from: data)
            clips = decoded
        } catch {
            print("[Mementi] Error loading clips: \(error)")
            clips = []
        }
    }

    public func save() {
        let items = self.clips
        let targetURL = self.fileURL
        queue.async {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(items)
                try data.write(to: targetURL, options: .atomic)
                // Restrict file permissions to owner read/write only (0600)
                try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: targetURL.path)
            } catch {
                print("[Mementi] Error saving clips: \(error)")
            }
        }
    }

    /// Add a new copied snippet, maintaining deduplication & preserving highlight status
    @discardableResult
    public func addClip(content: String) -> ClipItem? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // If it matches the very first item, avoid duplicate spam
        if let first = clips.first, first.content == content {
            return first
        }

        // If it already exists in history elsewhere, remove old position but preserve highlight
        var existingHighlight = false
        var existingHighlightedAt: Date? = nil

        if let existingIndex = clips.firstIndex(where: { $0.content == content }) {
            let oldItem = clips.remove(at: existingIndex)
            existingHighlight = oldItem.isHighlighted
            existingHighlightedAt = oldItem.highlightedAt
        }

        let newItem = ClipItem(
            content: content,
            createdAt: Date(),
            isHighlighted: existingHighlight,
            highlightedAt: existingHighlightedAt
        )

        clips.insert(newItem, at: 0)
        // Cap temporary unhighlighted clips to 1,000 items to avoid unbounded memory accumulation
        if clips.count > 1000, let oldestTemp = clips.lastIndex(where: { !$0.isHighlighted }) {
            clips.remove(at: oldestTemp)
        }
        save()
        return newItem
    }

    /// Highlight item with mouse - turns yellow and saves into Long Memory
    public func toggleHighlight(id: UUID) {
        guard let index = clips.firstIndex(where: { $0.id == id }) else { return }
        clips[index].isHighlighted.toggle()
        clips[index].highlightedAt = clips[index].isHighlighted ? Date() : nil
        save()
    }

    /// Explicitly set highlight state
    public func setHighlight(id: UUID, isHighlighted: Bool) {
        guard let index = clips.firstIndex(where: { $0.id == id }) else { return }
        clips[index].isHighlighted = isHighlighted
        clips[index].highlightedAt = isHighlighted ? Date() : nil
        save()
    }

    /// Delete a single clip
    public func deleteClip(id: UUID) {
        clips.removeAll { $0.id == id }
        save()
    }

    /// Prune un-highlighted items older than 3 days
    public func pruneExpiredItems() {
        let beforeCount = clips.count
        clips.removeAll { $0.isExpired }
        if clips.count != beforeCount {
            save()
        }
    }

    /// Clear all temporary (non-highlighted) clips, preserving Long Memory
    public func clearTemporaryClips() {
        clips.removeAll { !$0.isHighlighted }
        save()
    }

    /// Clear all clips
    public func clearAll() {
        clips.removeAll()
        save()
    }
}
