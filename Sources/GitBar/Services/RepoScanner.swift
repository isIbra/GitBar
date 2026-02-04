import Foundation

/// Recursively discovers git repositories within watched directories.
enum RepoScanner {

    /// Scans the given directories for git repos up to `maxDepth` levels deep.
    ///
    /// A directory is a git repo if it contains a `.git` folder (or `.git` file
    /// for worktrees/submodules).
    ///
    /// - Parameters:
    ///   - directories: Root directories to scan.
    ///   - maxDepth: Maximum recursion depth (default: 2).
    /// - Returns: An array of absolute paths to git repository roots.
    static func findRepos(
        in directories: [String],
        maxDepth: Int = 2
    ) -> [String] {
        var repos: [String] = []
        let fm = FileManager.default

        for directory in directories {
            scan(
                directory: directory,
                depth: 0,
                maxDepth: maxDepth,
                fileManager: fm,
                results: &repos
            )
        }

        // Deduplicate while preserving order
        return Array(NSOrderedSet(array: repos)) as? [String] ?? repos
    }

    // MARK: - Private

    private static func scan(
        directory: String,
        depth: Int,
        maxDepth: Int,
        fileManager fm: FileManager,
        results: inout [String]
    ) {
        // Don't exceed configured depth
        guard depth <= maxDepth else { return }

        let dirURL = URL(fileURLWithPath: directory)

        // Check if this directory itself is a git repo
        let gitDir = dirURL.appendingPathComponent(".git")
        if fm.fileExists(atPath: gitDir.path) {
            results.append(directory)
            return // Don't scan inside a git repo for nested repos
        }

        // Otherwise, scan subdirectories
        guard let children = try? fm.contentsOfDirectory(
            at: dirURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return }

        for child in children {
            guard let resourceValues = try? child.resourceValues(forKeys: [.isDirectoryKey]),
                  resourceValues.isDirectory == true else { continue }

            scan(
                directory: child.path,
                depth: depth + 1,
                maxDepth: maxDepth,
                fileManager: fm,
                results: &results
            )
        }
    }
}
