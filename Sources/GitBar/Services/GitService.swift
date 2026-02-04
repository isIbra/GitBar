import Foundation

/// Provides git operations for a single repository.
/// All methods are async and non-blocking.
enum GitService {

    /// Fetches the full status of a git repository at the given path.
    ///
    /// Runs multiple git commands concurrently for speed.
    static func status(for repoPath: String) async -> GitRepo {
        let name = URL(fileURLWithPath: repoPath).lastPathComponent

        // Run all git queries concurrently
        async let branchResult   = currentBranch(in: repoPath)
        async let statusResult   = porcelainStatus(in: repoPath)
        async let unpushedResult = unpushedCommits(in: repoPath)
        async let conflictResult = conflictFiles(in: repoPath)
        async let stashResult    = stashCount(in: repoPath)

        let branch    = await branchResult
        let status    = await statusResult
        let unpushed  = await unpushedResult
        let conflicts = await conflictResult
        let stashes   = await stashResult

        var repo = GitRepo(id: repoPath, name: name, path: repoPath)
        repo.branch         = branch
        repo.modifiedCount  = status.modified
        repo.stagedCount    = status.staged
        repo.untrackedCount = status.untracked
        repo.unpushedCount  = unpushed
        repo.conflictCount  = conflicts
        repo.stashCount     = stashes

        return repo
    }

    // MARK: - Individual Git Commands

    /// Returns the current branch name.
    private static func currentBranch(in directory: String) async -> String {
        let result = await ProcessRunner.git("rev-parse", "--abbrev-ref", "HEAD", in: directory)
        return result.succeeded ? result.stdout : "detached"
    }

    /// Parses `git status --porcelain` for change counts.
    private static func porcelainStatus(in directory: String) async -> (modified: Int, staged: Int, untracked: Int) {
        let result = await ProcessRunner.git("status", "--porcelain", in: directory)
        guard result.succeeded, !result.stdout.isEmpty else {
            return (0, 0, 0)
        }

        var modified = 0, staged = 0, untracked = 0

        for line in result.stdout.components(separatedBy: "\n") {
            guard line.count >= 2 else { continue }

            let index = line[line.startIndex]
            let worktree = line[line.index(line.startIndex, offsetBy: 1)]

            // Untracked files
            if index == "?" {
                untracked += 1
                continue
            }

            // Staged changes (index column)
            if index != " " && index != "?" {
                staged += 1
            }

            // Unstaged modifications (worktree column)
            if worktree != " " && worktree != "?" {
                modified += 1
            }
        }

        return (modified, staged, untracked)
    }

    /// Counts commits ahead of upstream.
    private static func unpushedCommits(in directory: String) async -> Int {
        let result = await ProcessRunner.git(
            "log", "@{u}..HEAD", "--oneline",
            in: directory
        )
        guard result.succeeded, !result.stdout.isEmpty else { return 0 }
        return result.stdout.components(separatedBy: "\n").count
    }

    /// Counts files with merge conflicts.
    private static func conflictFiles(in directory: String) async -> Int {
        let result = await ProcessRunner.git(
            "diff", "--name-only", "--diff-filter=U",
            in: directory
        )
        guard result.succeeded, !result.stdout.isEmpty else { return 0 }
        return result.stdout.components(separatedBy: "\n").count
    }

    /// Counts stash entries.
    private static func stashCount(in directory: String) async -> Int {
        let result = await ProcessRunner.git("stash", "list", in: directory)
        guard result.succeeded, !result.stdout.isEmpty else { return 0 }
        return result.stdout.components(separatedBy: "\n").count
    }

    // MARK: - Repo Actions

    /// Opens a repository in Terminal.
    static func openInTerminal(_ repoPath: String) {
        let script = """
        tell application "Terminal"
            do script "cd \(repoPath.replacingOccurrences(of: "\"", with: "\\\""))"
            activate
        end tell
        """
        runAppleScript(script)
    }

    /// Opens a repository in Finder.
    static func openInFinder(_ repoPath: String) {
        let script = """
        tell application "Finder"
            open POSIX file "\(repoPath)"
            activate
        end tell
        """
        runAppleScript(script)
    }

    /// Opens a repository with the configured editor command.
    static func openInEditor(_ repoPath: String, command: String) {
        Task {
            // Split the command — supports "code", "open -a Terminal", etc.
            let parts = command.components(separatedBy: " ")
            guard let executable = parts.first else { return }

            var args = Array(parts.dropFirst())
            args.append(repoPath)

            _ = await ProcessRunner.run(
                "/usr/bin/env",
                arguments: [executable] + args,
                workingDirectory: repoPath
            )
        }
    }

    // MARK: - Helpers

    private static func runAppleScript(_ source: String) {
        Task {
            _ = await ProcessRunner.run(
                "/usr/bin/osascript",
                arguments: ["-e", source]
            )
        }
    }
}
