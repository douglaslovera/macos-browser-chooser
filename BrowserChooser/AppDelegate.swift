import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appModel = AppModel()
    private var chooserWindow: ChooserWindow?

    func applicationWillFinishLaunching(_ notification: Notification) {
        Diagnostics.shared.start()
        Diagnostics.shared.info("Registering URL event handler")
        NSApp.setActivationPolicy(.accessory)

        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        appModel.onNeedsPresentation = { [weak self] in
            self?.showChooserIfNeeded()
        }

        appModel.refreshBrowsers()
        Diagnostics.shared.info("Application finished launching; discovered \(appModel.discoveredBrowsers.count) browsers")
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSAppleEventManager.shared().removeEventHandler(
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
        Diagnostics.shared.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc
    private func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let rawURL = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue else {
            Diagnostics.shared.error("Received URL event without a URL string")
            return
        }

        guard let url = URL(string: rawURL) else {
            Diagnostics.shared.error("Received malformed URL event")
            return
        }

        Diagnostics.shared.info("Received URL event for \(Diagnostics.shared.describe(url))")
        appModel.enqueue(url)
    }

    private func showChooserIfNeeded() {
        guard appModel.activeRequest != nil else {
            Diagnostics.shared.info("Closing chooser because there is no active request")
            chooserWindow?.close()
            chooserWindow = nil
            return
        }

        if chooserWindow == nil {
            Diagnostics.shared.info("Creating chooser window")
            chooserWindow = ChooserWindow(appModel: appModel)
        }

        Diagnostics.shared.info("Presenting chooser window")
        chooserWindow?.show()
    }
}
