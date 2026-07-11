import AppKit

struct URLRequestItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
}

@MainActor
final class AppModel: ObservableObject {
    @Published var discoveredBrowsers: [BrowserApp] = []
    @Published var activeRequest: URLRequestItem?
    @Published var errorMessage: String?
    @Published var isManagingBrowsers = false
    @Published var selectedBrowserID: BrowserApp.ID?

    var onNeedsPresentation: (() -> Void)?

    private let discovery = BrowserDiscovery()
    private var preferences = PreferencesStore()
    private var queue: [URLRequestItem] = []

    var visibleBrowsers: [BrowserApp] {
        orderedBrowsers.filter { !preferences.hiddenBrowserIDs.contains($0.id) }
    }

    var orderedBrowsers: [BrowserApp] {
        let browsersByID = Dictionary(uniqueKeysWithValues: discoveredBrowsers.map { ($0.id, $0) })
        let ordered = preferences.browserOrder.compactMap { browsersByID[$0] }
        let orderedIDs = Set(ordered.map(\.id))
        let unordered = discoveredBrowsers
            .filter { !orderedIDs.contains($0.id) }
            .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }

        return ordered + unordered
    }

    func enqueue(_ url: URL) {
        queue.append(URLRequestItem(url: url))
        Diagnostics.shared.info("Queued \(Diagnostics.shared.describe(url)); pending requests=\(queue.count)")
        showNextRequestIfNeeded()
    }

    func cancelActiveRequest() {
        finishActiveRequest()
    }

    func choose(_ browser: BrowserApp) {
        guard let request = activeRequest else {
            Diagnostics.shared.warning("Ignored browser selection because there is no active request")
            return
        }

        Diagnostics.shared.info("Opening \(Diagnostics.shared.describe(request.url)) with \(browser.displayName) (\(browser.id))")
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([request.url], withApplicationAt: browser.appURL, configuration: configuration) { [weak self] _, error in
            Task { @MainActor in
                guard let self else {
                    return
                }

                if let error {
                    Diagnostics.shared.error("Browser open failed: \(error.localizedDescription)")
                    self.errorMessage = "Could not open \(request.url.absoluteString) in \(browser.displayName): \(error.localizedDescription)"
                } else {
                    Diagnostics.shared.info("Browser open succeeded")
                    self.finishActiveRequest()
                }
            }
        }
    }

    func refreshBrowsers() {
        discoveredBrowsers = discovery.discoverBrowsers()
        Diagnostics.shared.info("Browser discovery returned \(discoveredBrowsers.count) apps")
        normalizePreferenceOrder()
        ensureSelectionIsVisible()
    }

    func isHidden(_ browser: BrowserApp) -> Bool {
        preferences.hiddenBrowserIDs.contains(browser.id)
    }

    func setHidden(_ browser: BrowserApp, hidden: Bool) {
        objectWillChange.send()

        if hidden {
            preferences.hiddenBrowserIDs.insert(browser.id)
        } else {
            preferences.hiddenBrowserIDs.remove(browser.id)
        }

        preferences.save()
        ensureSelectionIsVisible()
    }

    func moveBrowsers(from source: IndexSet, to destination: Int) {
        objectWillChange.send()

        var allBrowsers = orderedBrowsers
        allBrowsers.move(fromOffsets: source, toOffset: destination)
        preferences.browserOrder = allBrowsers.map(\.id)
        preferences.save()
    }

    func moveBrowserUp(_ browser: BrowserApp) {
        moveBrowser(browser, offset: -1)
    }

    func moveBrowserDown(_ browser: BrowserApp) {
        moveBrowser(browser, offset: 1)
    }

    func selectNextBrowser() {
        guard !visibleBrowsers.isEmpty else {
            return
        }

        let currentIndex = selectedBrowserID.flatMap { id in
            visibleBrowsers.firstIndex { $0.id == id }
        } ?? -1

        selectedBrowserID = visibleBrowsers[min(currentIndex + 1, visibleBrowsers.count - 1)].id
    }

    func selectPreviousBrowser() {
        guard !visibleBrowsers.isEmpty else {
            return
        }

        let currentIndex = selectedBrowserID.flatMap { id in
            visibleBrowsers.firstIndex { $0.id == id }
        } ?? visibleBrowsers.count

        selectedBrowserID = visibleBrowsers[max(currentIndex - 1, 0)].id
    }

    func chooseSelectedBrowser() {
        guard
            let selectedBrowserID,
            let browser = visibleBrowsers.first(where: { $0.id == selectedBrowserID })
        else {
            return
        }

        choose(browser)
    }

    private func showNextRequestIfNeeded() {
        guard activeRequest == nil, !queue.isEmpty else {
            return
        }

        activeRequest = queue.removeFirst()
        errorMessage = nil
        isManagingBrowsers = false
        ensureSelectionIsVisible()
        onNeedsPresentation?()
    }

    private func finishActiveRequest() {
        activeRequest = nil
        errorMessage = nil
        isManagingBrowsers = false
        onNeedsPresentation?()
        showNextRequestIfNeeded()
    }

    private func normalizePreferenceOrder() {
        let discoveredIDs = Set(discoveredBrowsers.map(\.id))
        preferences.browserOrder.removeAll { !discoveredIDs.contains($0) }
        preferences.save()
    }

    private func ensureSelectionIsVisible() {
        if let selectedBrowserID, visibleBrowsers.contains(where: { $0.id == selectedBrowserID }) {
            return
        }

        selectedBrowserID = visibleBrowsers.first?.id
    }

    private func moveBrowser(_ browser: BrowserApp, offset: Int) {
        var allBrowsers = orderedBrowsers
        guard let sourceIndex = allBrowsers.firstIndex(of: browser) else {
            return
        }

        let targetIndex = sourceIndex + offset
        guard allBrowsers.indices.contains(targetIndex) else {
            return
        }

        objectWillChange.send()
        allBrowsers.swapAt(sourceIndex, targetIndex)
        preferences.browserOrder = allBrowsers.map(\.id)
        preferences.save()
    }
}
