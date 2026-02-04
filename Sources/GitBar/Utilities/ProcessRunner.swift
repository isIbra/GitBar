import Foundation

/// Lightweight async wrapper around `Process` for running shell commands.
/// All git operations flow through here.
enum ProcessRunner {

    /// Result of a shell command execution.
    struct CommandResult {
        let stdout: String
        let stderr: String
        let exitCode: Int32
        var succeeded: Bool { exitCode == 0 }
    }

    /// Runs a command asynchronously and returns the result.
    ///
    /// - Parameters:
    ///   - executable: Path to the executable (e.g. "/usr/bin/git").
    ///   - arguments:  Arguments to pass.
    ///   - workingDirectory: Optional working directory for the process.
    ///   - environment: Optional environment variables to merge.
    /// - Returns: A `CommandResult` with stdout, stderr and exit code.
    static func run(
        _ executable: String = "/usr/bin/env",
        arguments: [String],
        workingDirectory: String? = nil,
        environment: [String: String]? = nil
    ) async -> CommandResult {
        await withCheckedContinuation { continuation in
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            if let dir = workingDirectory {
                process.currentDirectoryURL = URL(fileURLWithPath: dir)
            }

            if let env = environment {
                var merged = ProcessInfo.processInfo.environment
                for (key, value) in env { merged[key] = value }
                process.environment = merged
            }

            process.terminationHandler = { _ in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                let result = CommandResult(
                    stdout: String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                    stderr: String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                    exitCode: process.terminationStatus
                )
                continuation.resume(returning: result)
            }

            do {
                try process.run()
            } catch {
                let result = CommandResult(
                    stdout: "",
                    stderr: "Failed to launch process: \(error.localizedDescription)",
                    exitCode: -1
                )
                continuation.resume(returning: result)
            }
        }
    }

    /// Convenience: run `git` with the given arguments in a specific directory.
    static func git(
        _ arguments: String...,
        in directory: String
    ) async -> CommandResult {
        await run(
            "/usr/bin/git",
            arguments: Array(arguments),
            workingDirectory: directory
        )
    }
}
