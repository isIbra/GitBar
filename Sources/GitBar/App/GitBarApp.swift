import SwiftUI

/// GitBar — All your repos' git status at a glance from the menu bar.
///
/// This is the main entry point. We use `MenuBarExtra` (macOS 13+) to
/// create a persistent menu bar item with a popover-style window.
@main
struct GitBarApp: App {

    @StateObject private var appState = AppState()

    var body: some Scene {
        // Menu bar item with popover content
        MenuBarExtra {
            MenuBarView(appState: appState)
        } label: {
            MenuBarLabel(appState: appState)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Menu Bar Icon

/// The label displayed in the macOS menu bar.
///
/// Shows a branch icon with a color-coded status dot and optional
/// badge count for dirty repos.
struct MenuBarLabel: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: 4) {
            // Branch icon with status color overlay
            Image(systemName: "arrow.triangle.branch")

            // Color-coded dot
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)

            // Badge count if any repos need attention
            if appState.dirtyRepoCount > 0 {
                Text("\(appState.dirtyRepoCount)")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .monospacedDigit()
            }
        }
        .task {
            // Initial refresh when the app launches
            await appState.refresh()
        }
    }

    private var statusColor: Color {
        switch appState.overallStatus {
        case .conflict: return .red
        case .dirty:    return .orange
        case .clean:    return .green
        }
    }
}
