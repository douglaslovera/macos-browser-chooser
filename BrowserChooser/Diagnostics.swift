import Foundation
import os

@MainActor
final class Diagnostics {
    static let shared = Diagnostics()

    private let systemLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BrowserChooser", category: "lifecycle")
    private let fileManager = FileManager.default
    private let sessionID = UUID().uuidString.prefix(8)
    private let logDirectory: URL
    private let logFile: URL
    private let activeSessionFile: URL
    private let timestampFormatter = ISO8601DateFormatter()

    private init() {
        let library = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first!
        logDirectory = library.appendingPathComponent("Logs/BrowserChooser", isDirectory: true)
        logFile = logDirectory.appendingPathComponent("browserchooser.log")
        activeSessionFile = logDirectory.appendingPathComponent("active-session")
    }

    var logFilePath: String { logFile.path }

    func start() {
        prepareLogDirectory()
        rotateLogIfNeeded()

        if let previousSession = try? String(contentsOf: activeSessionFile, encoding: .utf8),
           !previousSession.isEmpty {
            record("warning", "Previous session \(previousSession) did not terminate cleanly")
        }

        try? String(sessionID).write(to: activeSessionFile, atomically: true, encoding: .utf8)
        record("info", "Application starting (version=\(appVersion), pid=\(ProcessInfo.processInfo.processIdentifier))")
    }

    func stop() {
        record("info", "Application terminating normally")
        try? fileManager.removeItem(at: activeSessionFile)
    }

    func info(_ message: String) { record("info", message) }
    func warning(_ message: String) { record("warning", message) }
    func error(_ message: String) { record("error", message) }

    func describe(_ url: URL) -> String {
        var result = url.scheme ?? "unknown-scheme"
        if let host = url.host(percentEncoded: false) {
            result += "://\(host)"
        }
        return result
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        return "\(version) (\(build))"
    }

    private func prepareLogDirectory() {
        try? fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
    }

    private func rotateLogIfNeeded() {
        guard
            let attributes = try? fileManager.attributesOfItem(atPath: logFile.path),
            let size = attributes[.size] as? NSNumber,
            size.intValue > 512_000
        else { return }

        let previousLog = logDirectory.appendingPathComponent("browserchooser.previous.log")
        try? fileManager.removeItem(at: previousLog)
        try? fileManager.moveItem(at: logFile, to: previousLog)
    }

    private func record(_ level: String, _ message: String) {
        systemLogger.log(level: level == "error" ? .error : .default, "\(message, privacy: .public)")

        let line = "\(timestampFormatter.string(from: Date())) [\(level.uppercased())] [session:\(sessionID)] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        if let handle = try? FileHandle(forWritingTo: logFile) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        } else {
            try? data.write(to: logFile, options: .atomic)
        }
    }
}
