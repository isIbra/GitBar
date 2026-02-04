import SwiftUI

/// Main popover content shown when the menu bar icon is clicked.
///
/// Displays a list of all watched repositories with their git status,
/// plus a header with stats and access to settings.
struct MenuBarView: View {
    @ObservedObject var appState: AppState

    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            header

            Divider()

            // MARK: - Repo List
            if appState.repos.isEmpty {
                emptyState
            } else {
                repoList
            }

            Divider()

            // MARK: - Footer
            footer
        }
        .frame(width: 400, height: min(CGFloat(appState.repos.count * 72 + 130), 520))
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: appState.settings)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("GitBar")
                    .font(.system(.headline, design: .rounded, weight: .bold))

                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Refresh button
            Button {
                Task { await appState.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.body)
                    .rotationEffect(.degrees(appState.isRefreshing ? 360 : 0))
                    .animation(
                        appState.isRefreshing
                            ? .linear(duration: 1).repeatForever(autoreverses: false)
                            : .default,
                        value: appState.isRefreshing
                    )
            }
            .buttonStyle(.plain)
            .help("Refresh all repos")

            // Settings button
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.body)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var headerSubtitle: String {
        let count = appState.repos.count
        if count == 0 {
            return "No repositories found"
        }
        let dirty = appState.dirtyRepoCount
        if dirty == 0 {
            return "Watching \(count) repo\(count == 1 ? "" : "s") — all clean ✓"
        }
        return "Watching \(count) repo\(count == 1 ? "" : "s") · \(dirty) need attention"
    }

    // MARK: - Repo List

    private var repoList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(appState.repos) { repo in
                    RepoRowView(
                        repo: repo,
                        editorCommand: appState.settings.editorCommand
                    )
                    .onTapGesture {
                        GitService.openInEditor(
                            repo.path,
                            command: appState.settings.editorCommand
                        )
                    }

                    if repo.id != appState.repos.last?.id {
                        Divider()
                            .padding(.horizontal, 12)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))

            VStack(spacing: 4) {
                Text("No repos found")
                    .font(.headline)
                    .foregroundColor(.secondary)

                if appState.settings.watchedDirectories.isEmpty {
                    Text("Open Settings to add directories to watch")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                } else {
                    Text("No git repos found in your watched directories")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }

            Button("Open Settings") {
                showSettings = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(overallStatusColor)
                    .frame(width: 8, height: 8)

                Text(overallStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private var overallStatusColor: Color {
        switch appState.overallStatus {
        case .conflict: return .red
        case .dirty:    return .orange
        case .clean:    return .green
        }
    }

    private var overallStatusText: String {
        switch appState.overallStatus {
        case .conflict: return "Conflicts detected"
        case .dirty:    return "Uncommitted changes"
        case .clean:    return "All clean"
        }
    }
}

// MARK: - Preview

#Preview {
    let state = AppState()
    MenuBarView(appState: state)
}
