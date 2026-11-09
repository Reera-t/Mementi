import AppKit
import ServiceManagement

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private var retentionTimer: Timer?
    private var popoverController: ClipboardPopoverController?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Guarantee this app runs strictly as an accessory (menu bar toolbar only, no dock icon)
        NSApp.setActivationPolicy(.accessory)

        // Automatically register to launch at login (macOS 13+)
        if #available(macOS 13.0, *) {
            if SMAppService.mainApp.status != .enabled {
                try? SMAppService.mainApp.register()
            }
        }

        setupStatusItem()
        setupPopover()
        setupRetentionTimer()

        // Start clipboard monitoring
        ClipboardObserver.shared.start()
    }

    public func applicationWillTerminate(_ notification: Notification) {
        ClipboardObserver.shared.stop()
        retentionTimer?.invalidate()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Menu Bar Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        // Use standard system SF Symbol with template rendering for dark/light toolbar
        if let image = NSImage(systemSymbolName: "paperclip", accessibilityDescription: "Mementi Clipboard") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "📎"
        }

        button.toolTip = "Mementi Clipboard (Click to open)"
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 500)
        popover.behavior = .transient
        popover.animates = true

        let controller = ClipboardPopoverController()
        controller.onCloseRequested = { [weak self] in
            self?.closePopover()
        }
        popover.contentViewController = controller

        self.popover = popover
        self.popoverController = controller
    }

    private func setupRetentionTimer() {
        // Run cleanup every hour to purge non-highlighted items older than 3 days
        retentionTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            StorageManager.shared.pruneExpiredItems()
        }
    }

    // MARK: - Actions

    @objc private func togglePopover(_ sender: AnyObject?) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu()
            return
        }

        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            closePopover()
        } else {
            showPopover(button: button)
        }
    }

    private func showPopover(button: NSStatusBarButton) {
        // Refresh expired items check when opening
        StorageManager.shared.pruneExpiredItems()
        popoverController?.reloadClips()

        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover?.contentViewController?.view.window?.makeKey()
        NSApp.activate(ignoringOtherApps: true)

        // Close on outside clicks
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    public func closePopover() {
        popover?.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Mementi", action: #selector(openFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Clear Unhighlighted Clips (Keep ❤️)", action: #selector(clearTemporaryFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Prune Expired Clips", action: #selector(pruneFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Mementi", action: #selector(quitFromMenu), keyEquivalent: "q"))

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil // Restore toggle behavior on next click
    }

    @objc private func openFromMenu() {
        if let button = statusItem?.button {
            showPopover(button: button)
        }
    }

    @objc private func clearTemporaryFromMenu() {
        StorageManager.shared.clearTemporaryClips()
        popoverController?.reloadClips()
    }

    @objc private func pruneFromMenu() {
        StorageManager.shared.pruneExpiredItems()
        popoverController?.reloadClips()
    }

    @objc private func quitFromMenu() {
        NSApp.terminate(nil)
    }
}
