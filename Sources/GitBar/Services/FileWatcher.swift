import Foundation

/// FSEvents-based file system watcher for instant git change detection.
///
/// Monitors watched directories and fires a callback when changes are
/// detected, with debouncing to avoid rapid-fire updates.
final class FileWatcher {

    // MARK: - Properties

    /// Callback fired when a change is detected. Receives the paths that changed.
    var onChange: (([String]) -> Void)?

    private var stream: FSEventStreamRef?
    private let debounceInterval: TimeInterval
    private var debounceTimer: Timer?
    private var pendingPaths: Set<String> = []
    private let queue = DispatchQueue(label: "com.isibra.GitBar.FileWatcher", qos: .utility)

    // MARK: - Init

    /// Creates a new file watcher.
    /// - Parameter debounceInterval: Minimum time between change notifications (default: 0.5s).
    init(debounceInterval: TimeInterval = 0.5) {
        self.debounceInterval = debounceInterval
    }

    deinit {
        stop()
    }

    // MARK: - Public API

    /// Starts watching the given directories for changes.
    ///
    /// Any previous watch is stopped first.
    func watch(directories: [String]) {
        stop()

        guard !directories.isEmpty else { return }

        let pathsToWatch = directories as CFArray
        let latency: CFTimeInterval = 0.3 // Coalesce events within 300ms

        // Context pointing to self for the C callback
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        guard let stream = FSEventStreamCreate(
            nil,
            fileWatcherCallback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            latency,
            UInt32(
                kFSEventStreamCreateFlagUseCFTypes |
                kFSEventStreamCreateFlagFileEvents |
                kFSEventStreamCreateFlagNoDefer
            )
        ) else {
            print("[FileWatcher] Failed to create FSEventStream")
            return
        }

        self.stream = stream
        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
    }

    /// Stops the current watch.
    func stop() {
        debounceTimer?.invalidate()
        debounceTimer = nil
        pendingPaths.removeAll()

        guard let stream = stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    // MARK: - Internal

    /// Called from the C callback when file system events arrive.
    fileprivate func handleEvents(paths: [String]) {
        // Filter for changes inside .git directories or alongside them
        let relevantPaths = paths.filter { path in
            path.contains("/.git/") || path.contains("/.git")
        }

        guard !relevantPaths.isEmpty else { return }

        // Extract repo roots from the changed paths
        let repoRoots = Set(relevantPaths.compactMap { path -> String? in
            // Find the .git component and take everything before it
            guard let range = path.range(of: "/.git") else { return nil }
            return String(path[..<range.lowerBound])
        })

        // Debounce: accumulate paths and fire after the interval
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.pendingPaths.formUnion(repoRoots)
            self.debounceTimer?.invalidate()
            self.debounceTimer = Timer.scheduledTimer(
                withTimeInterval: self.debounceInterval,
                repeats: false
            ) { [weak self] _ in
                guard let self else { return }
                let paths = Array(self.pendingPaths)
                self.pendingPaths.removeAll()
                self.onChange?(paths)
            }
        }
    }
}

// MARK: - FSEvents C Callback

/// Global C callback for FSEventStream — bridges to the Swift `FileWatcher`.
private func fileWatcherCallback(
    streamRef: ConstFSEventStreamRef,
    clientCallBackInfo: UnsafeMutableRawPointer?,
    numEvents: Int,
    eventPaths: UnsafeMutableRawPointer,
    eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    eventIds: UnsafePointer<FSEventStreamEventId>
) {
    guard let info = clientCallBackInfo else { return }
    let watcher = Unmanaged<FileWatcher>.fromOpaque(info).takeUnretainedValue()

    // Convert CFArray of CFString to [String]
    guard let cfPaths = unsafeBitCast(eventPaths, to: CFArray?.self) else { return }
    var paths: [String] = []
    for i in 0..<CFArrayGetCount(cfPaths) {
        if let cfStr = CFArrayGetValueAtIndex(cfPaths, i) {
            let str = unsafeBitCast(cfStr, to: CFString.self) as String
            paths.append(str)
        }
    }

    watcher.handleEvents(paths: paths)
}
