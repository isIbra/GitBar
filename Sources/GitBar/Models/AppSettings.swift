import Foundation
import SwiftUI

/// Persisted application settings backed by UserDefaults.
/// Observed by SwiftUI views for live updates.
final class AppSettings: ObservableObject {

    // MARK: - Keys

    private enum Key: String {
        case watchedDirectories
        case scanDepth
        case refreshInterval
        case editorCommand
        case launchAtLogin
    }

    // MARK: - Singleton

    static let shared = AppSettings()

    // MARK: - Published Properties

    /// Directories to scan for git repositories.
    @Published var watchedDirectories: [String] {
        didSet { save(.watchedDirectories, watchedDirectories) }
    }

    /// How many levels deep to search for `.git` folders (1–5).
    @Published var scanDepth: Int {
        didSet { save(.scanDepth, scanDepth) }
    }

    /// Auto-refresh interval in seconds. 0 = manual only.
    @Published var refreshInterval: TimeInterval {
        didSet { save(.refreshInterval, refreshInterval) }
    }

    /// Command used to open a repo in an editor.
    @Published var editorCommand: String {
        didSet { save(.editorCommand, editorCommand) }
    }

    /// Whether to launch GitBar at login.
    @Published var launchAtLogin: Bool {
        didSet { save(.launchAtLogin, launchAtLogin) }
    }

    // MARK: - Refresh Interval Options

    /// Human-readable options for the settings picker.
    static let refreshOptions: [(label: String, value: TimeInterval)] = [
        ("30 seconds", 30),
        ("1 minute",   60),
        ("5 minutes",  300),
        ("Manual only", 0),
    ]

    // MARK: - Init

    private let defaults = UserDefaults.standard

    private init() {
        // Load saved values or fall back to sensible defaults
        self.watchedDirectories = defaults.stringArray(forKey: Key.watchedDirectories.rawValue) ?? []
        self.scanDepth          = defaults.object(forKey: Key.scanDepth.rawValue) as? Int ?? 2
        self.refreshInterval    = defaults.object(forKey: Key.refreshInterval.rawValue) as? TimeInterval ?? 60
        self.editorCommand      = defaults.string(forKey: Key.editorCommand.rawValue) ?? "open -a Terminal"
        self.launchAtLogin      = defaults.bool(forKey: Key.launchAtLogin.rawValue)
    }

    // MARK: - Helpers

    private func save(_ key: Key, _ value: Any) {
        defaults.set(value, forKey: key.rawValue)
    }

    /// Adds a directory to the watch list if not already present.
    func addDirectory(_ path: String) {
        guard !watchedDirectories.contains(path) else { return }
        watchedDirectories.append(path)
    }

    /// Removes a directory from the watch list.
    func removeDirectory(at offsets: IndexSet) {
        watchedDirectories.remove(atOffsets: offsets)
    }

    /// Removes a specific directory path.
    func removeDirectory(_ path: String) {
        watchedDirectories.removeAll { $0 == path }
    }
}
