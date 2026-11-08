import AppKit

public final class ClipTableCellView: NSTableCellView {
    public static let identifier = NSUserInterfaceItemIdentifier("ClipTableCellView")

    private let containerView = NSBox()
    private let badgeLabel = NSTextField(labelWithString: "")
    private let timeLabel = NSTextField(labelWithString: "")
    private let snippetLabel = NSTextField(wrappingLabelWithString: "")
    private let metaLabel = NSTextField(labelWithString: "")

    public let highlightButton = NSButton()
    public let copyButton = NSButton()
    public let deleteButton = NSButton()

    public var onToggleHighlight: (() -> Void)?
    public var onCopy: (() -> Void)?
    public var onDelete: (() -> Void)?

    private var currentItem: ClipItem?
    private var trackingArea: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        wantsLayer = true

        // Container Box (acting as the card)
        containerView.boxType = .custom
        containerView.cornerRadius = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        // Status Badge (Long Memory vs Expiration Countdown)
        badgeLabel.font = NSFont.monospacedSystemFont(ofSize: 9.5, weight: .bold)
        badgeLabel.isBezeled = false
        badgeLabel.drawsBackground = false
        badgeLabel.isEditable = false
        badgeLabel.isSelectable = false
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(badgeLabel)

        // Time ago label
        timeLabel.font = NSFont.systemFont(ofSize: 9.5, weight: .regular)
        timeLabel.textColor = .secondaryLabelColor
        timeLabel.isBezeled = false
        timeLabel.drawsBackground = false
        timeLabel.isEditable = false
        timeLabel.isSelectable = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(timeLabel)

        // Snippet preview label
        snippetLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        snippetLabel.maximumNumberOfLines = 3
        snippetLabel.lineBreakMode = .byTruncatingTail
        snippetLabel.isBezeled = false
        snippetLabel.drawsBackground = false
        snippetLabel.isEditable = false
        snippetLabel.isSelectable = false
        snippetLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(snippetLabel)

        // Meta info label
        metaLabel.font = NSFont.systemFont(ofSize: 9.5, weight: .regular)
        metaLabel.textColor = .secondaryLabelColor
        metaLabel.isBezeled = false
        metaLabel.drawsBackground = false
        metaLabel.isEditable = false
        metaLabel.isSelectable = false
        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(metaLabel)

        // Highlight Button (Yellow Highlighter)
        highlightButton.bezelStyle = .inline
        highlightButton.isBordered = true
        highlightButton.target = self
        highlightButton.action = #selector(handleHighlightClick)
        highlightButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(highlightButton)

        // Copy Button
        copyButton.bezelStyle = .inline
        copyButton.isBordered = false
        copyButton.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Copy")
        copyButton.toolTip = "Copy to clipboard"
        copyButton.target = self
        copyButton.action = #selector(handleCopyClick)
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(copyButton)

        // Delete Button
        deleteButton.bezelStyle = .inline
        deleteButton.isBordered = false
        deleteButton.image = NSImage(systemSymbolName: "trash", accessibilityDescription: "Delete")
        deleteButton.toolTip = "Delete clip"
        deleteButton.target = self
        deleteButton.action = #selector(handleDeleteClick)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            badgeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            badgeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),

            timeLabel.centerYAnchor.constraint(equalTo: badgeLabel.centerYAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: badgeLabel.trailingAnchor, constant: 6),

            deleteButton.centerYAnchor.constraint(equalTo: badgeLabel.centerYAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            deleteButton.widthAnchor.constraint(equalToConstant: 22),
            deleteButton.heightAnchor.constraint(equalToConstant: 20),

            copyButton.centerYAnchor.constraint(equalTo: badgeLabel.centerYAnchor),
            copyButton.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -4),
            copyButton.widthAnchor.constraint(equalToConstant: 22),
            copyButton.heightAnchor.constraint(equalToConstant: 20),

            highlightButton.centerYAnchor.constraint(equalTo: badgeLabel.centerYAnchor),
            highlightButton.trailingAnchor.constraint(equalTo: copyButton.leadingAnchor, constant: -6),
            highlightButton.heightAnchor.constraint(equalToConstant: 20),

            snippetLabel.topAnchor.constraint(equalTo: badgeLabel.bottomAnchor, constant: 6),
            snippetLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            snippetLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),

            metaLabel.topAnchor.constraint(equalTo: snippetLabel.bottomAnchor, constant: 6),
            metaLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            metaLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
    }

    public func configure(with item: ClipItem) {
        self.currentItem = item

        snippetLabel.stringValue = item.previewSnippet
        metaLabel.stringValue = "\(item.charCount) chars  •  \(item.lineCount) line\(item.lineCount == 1 ? "" : "s")"

        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        if item.isHighlighted {
            // Highlighting active: Vibrant Yellow Highlight Card
            badgeLabel.stringValue = "❤️ LONG MEMORY"
            timeLabel.stringValue = "•  \(item.timeAgoText)"
            badgeLabel.textColor = isDark
                ? NSColor(srgbRed: 0.99, green: 0.85, blue: 0.30, alpha: 1.0)
                : NSColor(srgbRed: 0.45, green: 0.35, blue: 0.0, alpha: 1.0)

            containerView.fillColor = isDark
                ? NSColor(srgbRed: 0.32, green: 0.25, blue: 0.05, alpha: 0.95)
                : NSColor(srgbRed: 1.0, green: 0.97, blue: 0.65, alpha: 0.98) // Fluorescent Canary Yellow
            containerView.borderColor = isDark
                ? NSColor(srgbRed: 0.95, green: 0.78, blue: 0.15, alpha: 1.0)
                : NSColor(srgbRed: 0.88, green: 0.72, blue: 0.08, alpha: 1.0)
            containerView.borderWidth = 1.6

            snippetLabel.textColor = isDark
                ? NSColor(srgbRed: 0.98, green: 0.98, blue: 0.90, alpha: 1.0)
                : NSColor(srgbRed: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)

            highlightButton.title = "Highlighted"
            highlightButton.image = NSImage(systemSymbolName: "highlighter", accessibilityDescription: "Highlighted")
            highlightButton.contentTintColor = isDark ? .white : NSColor(srgbRed: 0.4, green: 0.3, blue: 0.0, alpha: 1.0)
            highlightButton.toolTip = "Click with mouse to remove yellow highlight (unfavorite)"
        } else {
            // Standard Temporary Card (no time left)
            badgeLabel.stringValue = item.timeAgoText
            timeLabel.stringValue = ""
            badgeLabel.textColor = .secondaryLabelColor

            containerView.fillColor = isDark
                ? NSColor(white: 0.18, alpha: 0.8)
                : NSColor(white: 0.96, alpha: 0.9)
            containerView.borderColor = isDark
                ? NSColor(white: 0.3, alpha: 0.5)
                : NSColor(white: 0.8, alpha: 0.6)
            containerView.borderWidth = 0.8

            snippetLabel.textColor = .labelColor

            highlightButton.title = "Highlight"
            highlightButton.image = NSImage(systemSymbolName: "highlighter", accessibilityDescription: "Highlight")
            highlightButton.contentTintColor = NSColor(srgbRed: 0.85, green: 0.65, blue: 0.0, alpha: 1.0)
            highlightButton.toolTip = "Click with mouse to turn yellow and save to ❤️"
        }
    }

    @objc private func handleHighlightClick() {
        onToggleHighlight?()
    }

    @objc private func handleCopyClick() {
        onCopy?()
        flashCopySuccess()
    }

    @objc private func handleDeleteClick() {
        onDelete?()
    }

    public func flashCopySuccess() {
        badgeLabel.stringValue = "✓ COPIED TO CLIPBOARD!"
        badgeLabel.textColor = NSColor.systemGreen
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self, let item = self.currentItem else { return }
            self.configure(with: item)
        }
    }
}
