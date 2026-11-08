import AppKit
import Combine

public final class ClipboardPopoverController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate {
    private let searchField = NSSearchField()
    private let segmentedControl = NSSegmentedControl()
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let emptyLabel = NSTextField(wrappingLabelWithString: "")
    private let footerLabel = NSTextField(labelWithString: "")
    private let countLabel = NSTextField(labelWithString: "")

    private var cancellables = Set<AnyCancellable>()
    private var allClips: [ClipItem] = []
    private var displayedClips: [ClipItem] = []

    public var onCloseRequested: (() -> Void)?

    override public func loadView() {
        let root = NSVisualEffectView()
        root.material = .popover
        root.blendingMode = .behindWindow
        root.state = .active
        root.frame = NSRect(x: 0, y: 0, width: 380, height: 500)
        self.view = root
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindStorage()
        reloadClips()
    }

    private func setupUI() {
        // --- Header Section ---
        let headerBox = NSView()
        headerBox.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerBox)

        let titleLabel = NSTextField(labelWithString: "📎 Mementi")
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerBox.addSubview(titleLabel)

        let versionLabel = NSTextField(labelWithString: "v1.0")
        versionLabel.font = NSFont.systemFont(ofSize: 9, weight: .regular)
        versionLabel.textColor = .tertiaryLabelColor
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        headerBox.addSubview(versionLabel)

        // Menu button
        let menuButton = NSButton()
        menuButton.bezelStyle = .inline
        menuButton.image = NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: "Menu")
        menuButton.target = self
        menuButton.action = #selector(showOptionsMenu(_:))
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        headerBox.addSubview(menuButton)

        // --- Search Field ---
        searchField.placeholderString = "Search clipboard history..."
        searchField.delegate = self
        searchField.target = self
        searchField.action = #selector(searchChanged)
        searchField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchField)

        // --- Filter Tabs (Segmented Control) ---
        segmentedControl.segmentCount = 2
        segmentedControl.setLabel("All", forSegment: 0)
        segmentedControl.setLabel("❤️", forSegment: 1)
        segmentedControl.selectedSegment = 0
        segmentedControl.target = self
        segmentedControl.action = #selector(filterSegmentChanged)
        segmentedControl.segmentStyle = .texturedRounded
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)

        // --- Table View & Scroll View ---
        tableView.headerView = nil
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 88
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .none
        tableView.intercellSpacing = NSSize(width: 0, height: 2)
        tableView.target = self
        tableView.doubleAction = #selector(rowDoubleClicked)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ClipColumn"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Empty state label
        emptyLabel.alignment = .center
        emptyLabel.font = NSFont.systemFont(ofSize: 12)
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.stringValue = "No clips yet.\nCopy any text and it will appear here."
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)

        // --- Footer Bar ---
        let footerBox = NSView()
        footerBox.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(footerBox)

        footerLabel.font = NSFont.systemFont(ofSize: 9.5)
        footerLabel.textColor = .secondaryLabelColor
        footerLabel.stringValue = "💡 Click highlighter with mouse to turn yellow & save to ❤️"
        footerLabel.translatesAutoresizingMaskIntoConstraints = false
        footerBox.addSubview(footerLabel)

        countLabel.font = NSFont.monospacedSystemFont(ofSize: 9.5, weight: .regular)
        countLabel.textColor = .secondaryLabelColor
        countLabel.alignment = .right
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        footerBox.addSubview(countLabel)

        // Layout Constraints
        NSLayoutConstraint.activate([
            headerBox.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            headerBox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            headerBox.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            headerBox.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: headerBox.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerBox.centerYAnchor),

            versionLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 4),
            versionLabel.firstBaselineAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor),

            menuButton.trailingAnchor.constraint(equalTo: headerBox.trailingAnchor),
            menuButton.centerYAnchor.constraint(equalTo: headerBox.centerYAnchor),
            menuButton.widthAnchor.constraint(equalToConstant: 24),

            searchField.topAnchor.constraint(equalTo: headerBox.bottomAnchor, constant: 8),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            segmentedControl.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            scrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: footerBox.topAnchor, constant: -6),

            emptyLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            emptyLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            footerBox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            footerBox.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            footerBox.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            footerBox.heightAnchor.constraint(equalToConstant: 18),

            footerLabel.leadingAnchor.constraint(equalTo: footerBox.leadingAnchor),
            footerLabel.centerYAnchor.constraint(equalTo: footerBox.centerYAnchor),

            countLabel.trailingAnchor.constraint(equalTo: footerBox.trailingAnchor),
            countLabel.centerYAnchor.constraint(equalTo: footerBox.centerYAnchor)
        ])
    }

    private func bindStorage() {
        StorageManager.shared.$clips
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newClips in
                self?.allClips = newClips
                self?.reloadClips()
            }
            .store(in: &cancellables)
    }

    public func reloadClips() {
        let query = searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let segment = segmentedControl.selectedSegment

        var filtered = allClips

        // Filter by segment: 0 = All, 1 = ❤️ (Long Memory / Highlighted)
        if segment == 1 {
            filtered = filtered.filter { $0.isHighlighted }
        }

        // Filter by search query
        if !query.isEmpty {
            filtered = filtered.filter { $0.content.lowercased().contains(query) }
        }

        self.displayedClips = filtered
        tableView.reloadData()

        segmentedControl.setLabel("All", forSegment: 0)
        segmentedControl.setLabel("❤️", forSegment: 1)

        countLabel.stringValue = "\(displayedClips.count) / \(allClips.count)"

        // Update empty state
        if displayedClips.isEmpty {
            emptyLabel.isHidden = false
            if segment == 1 {
                emptyLabel.stringValue = "No ❤️ clips yet.\nClick the highlighter with your mouse on any clip to turn it yellow and save it to ❤️."
            } else if !query.isEmpty {
                emptyLabel.stringValue = "No clips match \"\(searchField.stringValue)\""
            } else {
                emptyLabel.stringValue = "Clipboard is empty.\nCopy text anywhere and it will appear here."
            }
        } else {
            emptyLabel.isHidden = true
        }
    }

    // MARK: - NSTableViewDataSource & Delegate

    public func numberOfRows(in tableView: NSTableView) -> Int {
        return displayedClips.count
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < displayedClips.count else { return nil }
        let item = displayedClips[row]

        var cell = tableView.makeView(withIdentifier: ClipTableCellView.identifier, owner: self) as? ClipTableCellView
        if cell == nil {
            cell = ClipTableCellView(frame: NSRect(x: 0, y: 0, width: tableView.bounds.width, height: 88))
            cell?.identifier = ClipTableCellView.identifier
        }

        cell?.configure(with: item)

        cell?.onToggleHighlight = { [weak self] in
            StorageManager.shared.toggleHighlight(id: item.id)
            self?.reloadClips()
        }

        cell?.onCopy = {
            ClipboardObserver.shared.copyToPasteboard(text: item.content)
        }

        cell?.onDelete = { [weak self] in
            StorageManager.shared.deleteClip(id: item.id)
            self?.reloadClips()
        }

        return cell
    }

    @objc private func rowDoubleClicked() {
        let row = tableView.clickedRow
        guard row >= 0, row < displayedClips.count else { return }
        let item = displayedClips[row]
        ClipboardObserver.shared.copyToPasteboard(text: item.content)
        if let cell = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? ClipTableCellView {
            cell.flashCopySuccess()
        }
    }

    // MARK: - Actions

    @objc private func searchChanged() {
        reloadClips()
    }

    public func controlTextDidChange(_ obj: Notification) {
        reloadClips()
    }

    @objc private func filterSegmentChanged() {
        reloadClips()
    }

    @objc private func showOptionsMenu(_ sender: NSButton) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Clean Expired Clips", action: #selector(pruneExpired), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Clear Unhighlighted Clips (Keep ❤️)", action: #selector(clearTemporary), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Clear All Clips...", action: #selector(clearAllClips), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Mementi", action: #selector(quitApp), keyEquivalent: "q"))

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
    }

    @objc private func pruneExpired() {
        StorageManager.shared.pruneExpiredItems()
        reloadClips()
    }

    @objc private func clearTemporary() {
        StorageManager.shared.clearTemporaryClips()
        reloadClips()
    }

    @objc private func clearAllClips() {
        let alert = NSAlert()
        alert.messageText = "Clear All Clips?"
        alert.informativeText = "This will delete all clips including those saved in Long Memory. This action cannot be undone."
        alert.addButton(withTitle: "Cancel")
        let deleteBtn = alert.addButton(withTitle: "Clear All")
        deleteBtn.hasDestructiveAction = true

        if alert.runModal() == .alertSecondButtonReturn {
            StorageManager.shared.clearAll()
            reloadClips()
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
