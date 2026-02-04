import Foundation

/// Represents the current status of a single git repository.
struct GitRepo: Identifiable, Equatable {
    let id: String          // Absolute path to the repo root
    let name: String        // Folder name (last path component)
    let path: String        // Full path to the repo root

    var branch: String = "unknown"
    var modifiedCount: Int = 0
    var stagedCount: Int = 0
    var untrackedCount: Int = 0
    var conflictCount: Int = 0
    var unpushedCount: Int = 0
    var unpulledCount: Int = 0
    var stashCount: Int = 0

    /// True if the repo has any uncommitted changes.
    var isDirty: Bool {
        modifiedCount > 0 || stagedCount > 0 || untrackedCount > 0
    }

    /// True if the repo has merge conflicts.
    var hasConflicts: Bool {
        conflictCount > 0
    }

    /// Overall status for color-coding and sorting.
    var status: RepoStatus {
        if hasConflicts { return .conflict }
        if isDirty || unpushedCount > 0 { return .dirty }
        return .clean
    }

    /// Total number of changes (for badge display).
    var totalChanges: Int {
        modifiedCount + stagedCount + untrackedCount
    }
}

/// High-level status of a repository, used for color-coding.
enum RepoStatus: Int, Comparable, CaseIterable {
    case conflict = 0   // Red — most urgent, sorts first
    case dirty    = 1   // Yellow
    case clean    = 2   // Green

    static func < (lhs: RepoStatus, rhs: RepoStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension GitRepo {
    /// Creates a placeholder repo for previews and testing.
    static func preview(
        name: String = "my-project",
        branch: String = "main",
        modified: Int = 0,
        unpushed: Int = 0,
        conflicts: Int = 0
    ) -> GitRepo {
        var repo = GitRepo(
            id: "/Users/dev/\(name)",
            name: name,
            path: "/Users/dev/\(name)"
        )
        repo.branch = branch
        repo.modifiedCount = modified
        repo.unpushedCount = unpushed
        repo.conflictCount = conflicts
        return repo
    }
}
