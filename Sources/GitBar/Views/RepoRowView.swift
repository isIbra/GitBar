import SwiftUI

/// A single row representing one git repository in the popover list.
///
/// Shows the repo name, branch, change counts, and a color-coded
/// left border indicating status.
struct RepoRowView: View {
    let repo: GitRepo
    let editorCommand: String

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Color-coded status bar
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor)
                .frame(width: 4)

            // Repo info
            VStack(alignment: .leading, spacing: 4) {
                // Top row: name + branch
                HStack(spacing: 8) {
                    Text(repo.name)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .lineLimit(1)

                    // Branch pill
                    Text(repo.branch)
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                        )
                        .lineLimit(1)

                    Spacer()
                }

                // Bottom row: status indicators
                HStack(spacing: 12) {
                    if repo.modifiedCount > 0 {
                        StatusBadge(
                            icon: "pencil.circle.fill",
                            count: repo.modifiedCount,
                            color: .orange,
                            label: "modified"
                        )
                    }

                    if repo.stagedCount > 0 {
                        StatusBadge(
                            icon: "plus.circle.fill",
                            count: repo.stagedCount,
                            color: .green,
                            label: "staged"
                        )
                    }

                    if repo.untrackedCount > 0 {
                        StatusBadge(
                            icon: "questionmark.circle.fill",
                            count: repo.untrackedCount,
                            color: .secondary,
                            label: "untracked"
                        )
                    }

                    if repo.unpushedCount > 0 {
                        StatusBadge(
                            icon: "arrow.up.circle.fill",
                            count: repo.unpushedCount,
                            color: .blue,
                            label: "unpushed"
                        )
                    }

                    if repo.conflictCount > 0 {
                        StatusBadge(
                            icon: "exclamationmark.triangle.fill",
                            count: repo.conflictCount,
                            color: .red,
                            label: "conflicts"
                        )
                    }

                    if repo.stashCount > 0 {
                        StatusBadge(
                            icon: "archivebox.fill",
                            count: repo.stashCount,
                            color: .purple,
                            label: "stashed"
                        )
                    }

                    if repo.status == .clean && repo.unpushedCount == 0 {
                        Label("Clean", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    Spacer()

                    // Repo path (abbreviated)
                    Text(abbreviatedPath)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.secondary.opacity(0.08) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button {
                GitService.openInTerminal(repo.path)
            } label: {
                Label("Open in Terminal", systemImage: "terminal.fill")
            }

            Button {
                GitService.openInFinder(repo.path)
            } label: {
                Label("Open in Finder", systemImage: "folder.fill")
            }

            Button {
                GitService.openInEditor(repo.path, command: editorCommand)
            } label: {
                Label("Open in Editor", systemImage: "curlybraces")
            }

            Divider()

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(repo.path, forType: .string)
            } label: {
                Label("Copy Path", systemImage: "doc.on.doc")
            }
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch repo.status {
        case .conflict: return .red
        case .dirty:    return .orange
        case .clean:    return .green
        }
    }

    private var abbreviatedPath: String {
        let path = repo.path
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

// MARK: - Status Badge Component

/// Small icon + count badge for a specific status type.
struct StatusBadge: View {
    let icon: String
    let count: Int
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
            Text("\(count)")
                .font(.system(.caption, design: .monospaced, weight: .medium))
        }
        .foregroundColor(color)
        .help("\(count) \(label)")
    }
}

// MARK: - Preview

struct RepoRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            RepoRowView(
                repo: .preview(name: "gitbar", branch: "main"),
                editorCommand: "code"
            )
            Divider()
            RepoRowView(
                repo: .preview(name: "my-api", branch: "feature/auth", modified: 3, unpushed: 2),
                editorCommand: "code"
            )
            Divider()
            RepoRowView(
                repo: .preview(name: "broken-project", branch: "develop", modified: 1, conflicts: 2),
                editorCommand: "code"
            )
        }
        .frame(width: 380)
        .padding()
    }
}
