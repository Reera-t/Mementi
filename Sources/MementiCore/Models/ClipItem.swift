import Foundation

public struct ClipItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public var content: String
    public let createdAt: Date
    public var isHighlighted: Bool // Yellow highlight = saved in Long Memory (permanent)
    public var highlightedAt: Date?

    public static let defaultRetentionSeconds: TimeInterval = 3 * 24 * 60 * 60 // 3 days

    public init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = Date(),
        isHighlighted: Bool = false,
        highlightedAt: Date? = nil
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.isHighlighted = isHighlighted
        self.highlightedAt = highlightedAt
    }

    /// An item expires after 3 days unless it was highlighted into Long Memory
    public var isExpired: Bool {
        if isHighlighted { return false }
        return Date().timeIntervalSince(createdAt) >= Self.defaultRetentionSeconds
    }

    /// Remaining time before this item expires from 3-day temporary memory
    public var remainingTimeText: String {
        if isHighlighted {
            return "Long Memory"
        }
        let elapsed = Date().timeIntervalSince(createdAt)
        let remaining = Self.defaultRetentionSeconds - elapsed
        if remaining <= 0 {
            return "Expiring soon"
        }

        let days = Int(remaining / 86400)
        let hours = Int((remaining.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)

        if days > 0 {
            return "\(days)d \(hours)h left"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(max(1, minutes))m left"
        }
    }

    /// Relative creation time text
    public var timeAgoText: String {
        let elapsed = Date().timeIntervalSince(createdAt)
        if elapsed < 60 {
            return "Just now"
        } else if elapsed < 3600 {
            let m = Int(elapsed / 60)
            return "\(m)m ago"
        } else if elapsed < 86400 {
            let h = Int(elapsed / 3600)
            return "\(h)h ago"
        } else {
            let d = Int(elapsed / 86400)
            return "\(d)d ago"
        }
    }

    /// Preview text snippet for search or display
    public var previewSnippet: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let singleLine = trimmed.replacingOccurrences(of: "\n", with: " ")
        if singleLine.count > 120 {
            return String(singleLine.prefix(120)) + "…"
        }
        return singleLine
    }

    public var lineCount: Int {
        content.components(separatedBy: .newlines).count
    }

    public var charCount: Int {
        content.count
    }
}
