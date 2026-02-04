import SwiftUI
import ServiceManagement

/// Settings panel for configuring watched directories, refresh interval,
/// scan depth, editor, and launch-at-login.
struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var showFolderPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: - Watched Directories
                    settingsSection("Watched Directories", icon: "folder.badge.gearshape") {
                        VStack(alignment: .leading, spacing: 8) {
                            if settings.watchedDirectories.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Image(systemName: "folder.badge.questionmark")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                        Text("No directories configured")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("Add a folder containing your git repos")
                                            .font(.caption)
                                            .foregroundColor(.secondary.opacity(0.7))
                                    }
                                    .padding(.vertical, 16)
                                    Spacer()
                                }
                            } else {
                                ForEach(settings.watchedDirectories, id: \.self) { dir in
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.accentColor)
                                        Text(abbreviate(dir))
                                            .font(.system(.body, design: .monospaced))
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        Spacer()
                                        Button {
                                            withAnimation {
                                                settings.removeDirectory(dir)
                                            }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }

                            Button {
                                showFolderPicker = true
                            } label: {
                                Label("Add Directory…", systemImage: "plus.circle.fill")
                            }
                            .fileImporter(
                                isPresented: $showFolderPicker,
                                allowedContentTypes: [.folder],
                                allowsMultipleSelection: false
                            ) { result in
                                if case .success(let urls) = result, let url = urls.first {
                                    // Start accessing the security-scoped resource
                                    let _ = url.startAccessingSecurityScopedResource()
                                    withAnimation {
                                        settings.addDirectory(url.path)
                                    }
                                }
                            }
                        }
                    }

                    // MARK: - Scan Depth
                    settingsSection("Scan Depth", icon: "arrow.down.right.and.arrow.up.left") {
                        VStack(alignment: .leading, spacing: 4) {
                            Picker("", selection: $settings.scanDepth) {
                                ForEach(1...5, id: \.self) { depth in
                                    Text("\(depth) level\(depth == 1 ? "" : "s")")
                                        .tag(depth)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text("How deep to search for .git folders in watched directories")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // MARK: - Refresh Interval
                    settingsSection("Refresh Interval", icon: "arrow.clockwise") {
                        VStack(alignment: .leading, spacing: 4) {
                            Picker("", selection: $settings.refreshInterval) {
                                ForEach(AppSettings.refreshOptions, id: \.value) { option in
                                    Text(option.label).tag(option.value)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text("FSEvents provides instant updates — this is the fallback polling interval")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // MARK: - Editor
                    settingsSection("Default Editor", icon: "curlybraces") {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Editor command", text: $settings.editorCommand)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))

                            Text("Examples: code, open -a Terminal, open -a \"Sublime Text\"")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // MARK: - Launch at Login
                    settingsSection("General", icon: "gearshape") {
                        Toggle("Launch GitBar at login", isOn: $settings.launchAtLogin)
                            .onChange(of: settings.launchAtLogin) { _, newValue in
                                updateLaunchAtLogin(newValue)
                            }
                    }
                }
                .padding()
            }
        }
        .frame(width: 440, height: 580)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func settingsSection<Content: View>(
        _ title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(.headline, design: .rounded))

            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func abbreviate(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("[Settings] Failed to update launch at login: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView(settings: .shared)
}
