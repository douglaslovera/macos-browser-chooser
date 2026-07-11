import AppKit
import SwiftUI

@MainActor
final class ChooserWindow {
    private let window: NSWindow

    init(appModel: AppModel) {
        let contentView = ChooserView(appModel: appModel)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 410),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "Choose Browser"
        window.minSize = NSSize(width: 560, height: 352)
        window.maxSize = NSSize(width: 760, height: 560)
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
    }

    func show() {
        centerOnActiveScreen()
        window.orderOut(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        Diagnostics.shared.info("Chooser visible=\(window.isVisible), key=\(window.isKeyWindow), frame=\(NSStringFromRect(window.frame))")
    }

    func close() {
        window.close()
    }

    private func centerOnActiveScreen() {
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main

        guard let visibleFrame = targetScreen?.visibleFrame else {
            window.center()
            return
        }

        let frame = window.frame
        let origin = NSPoint(
            x: visibleFrame.midX - frame.width / 2,
            y: visibleFrame.midY - frame.height / 2
        )
        window.setFrameOrigin(origin)
    }
}
