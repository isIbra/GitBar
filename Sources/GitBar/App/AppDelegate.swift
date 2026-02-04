import AppKit
import SwiftUI

/// Central coordinator for the GitBar application.
///
/// Manages the lifecycle of repo scanning, status updates, file watching,
/// and exposes the data that drives the menu bar UI.
@MainActor
final class AppState: ObservableObject {

    // MARK: - Published State

    /// All discovered repositories and their statuses.
    @Published var repos: [GitRepo] = []

    /// Whether a refresh is currently in progress.
    @Published var isRefreshing: Bool = false

    /// Whether the settings window should be shown.
    @Published var showSettings: Bool = false

    // MARK: - Dependencies

    let settings = AppSettings.shared
    private let fileWatcher = FileWatcher()
    private var refreshTimer: Timer?

    // MARK: - Computed Properties

    /// Aggregate status across all repos (worst wins).
    var overallStatus: RepoStatus {
        if repos.contains(where: { $0.hasConflicts }) { return .conflict }
        if repos.contains(where: { $0.isDirty || $0.unpushedCount > 0 }) { return .dirty }
        return .clean
    }

    /// Count of repos that are dirty or have conflicts.
    var dirtyRepoCount: Int {
        repos.filter { $0.status != .clean }.count
    }

    // MARK: - Init

    init() {
        setupFileWatcher()
        setupRefreshTimer()

        // Observe settings changes
        settings.objectWillChange.sink { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.setupRefreshTimer()
                self?.setupFileWatcher()
                await self?.refresh()
            }
        }
        .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Refresh

    /// Performs a full scan + status check for all repos.
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        // Discover repos
        let repoPaths = RepoScanner.findRepos(
            in: settings.watchedDirectories,
            maxDepth: settings.scanDepth
        )

        // Fetch status for each repo concurrently
        let updatedRepos = await withTaskGroup(of: GitRepo.self, returning: [GitRepo].self) { group in
            for path in repoPaths {
                group.addTask {
                    await GitService.status(for: path)
                }
            }

            var results: [GitRepo] = []
            for await repo in group {
                results.append(repo)
            }
            return results
        }

        // Sort: conflicts first, then dirty, then clean; alphabetically within each group
        repos = updatedRepos.sorted { lhs, rhs in
            if lhs.status != rhs.status { return lhs.status < rhs.status }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    /// Refreshes only the specified repo paths (used by file watcher).
    func refreshRepos(at paths: [String]) async {
        for path in paths {
            let updated = await GitService.status(for: path)
            if let index = repos.firstIndex(where: { $0.id == path }) {
                repos[index] = updated
            }
        }

        // Re-sort
        repos.sort { lhs, rhs in
            if lhs.status != rhs.status { return lhs.status < rhs.status }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    // MARK: - File Watching

    private func setupFileWatcher() {
        fileWatcher.onChange = { [weak self] changedPaths in
            Task { @MainActor [weak self] in
                await self?.refreshRepos(at: changedPaths)
            }
        }
        fileWatcher.watch(directories: settings.watchedDirectories)
    }

    // MARK: - Timer

    private func setupRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil

        let interval = settings.refreshInterval
        guard interval > 0 else { return }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }
}

import Combine
