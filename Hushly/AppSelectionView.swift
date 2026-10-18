import AppKit
import SwiftUI

struct AppSelectionView: View {
    @EnvironmentObject private var privacy: PrivacyController

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().padding(.vertical, 12)
            appHeader

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(privacy.runningApps, id: \.processIdentifier) { app in
                        if let identifier = app.bundleIdentifier {
                            appRow(app, id: identifier)
                        }
                    }
                }
            }
            .frame(height: min(CGFloat(privacy.runningApps.count) * 42, 246))
            .padding(.top, 5)

            Divider().padding(.vertical, 12)
            actionArea
            Divider().padding(.vertical, 12)
            footer
        }
        .padding(16)
        .frame(width: 360)
    }

    private var header: some View {
        HStack(spacing: 9) {
            Image(systemName: "eye.slash")
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text("Hushly").font(.headline)
                Text("Keep personal apps out of meetings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(privacy.isCloaked ? "HIDDEN" : "READY")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(privacy.isCloaked ? Color.orange : Color.secondary)
        }
    }

    private var appHeader: some View {
        HStack {
            Text("APPS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(privacy.protectedIDs.count) selected")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
            Button {
                privacy.refreshRunningApps()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Refresh running apps")
        }
    }

    private func appRow(_ app: NSRunningApplication, id: String) -> some View {
        let selected = privacy.protectedIDs.contains(id)
        let visible = privacy.temporarilyVisibleIDs.contains(id)

        return HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { privacy.protectedIDs.contains(id) },
                set: { _ in privacy.toggleProtection(id) }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)
            .frame(width: 18)

            Image(nsImage: app.icon ?? NSImage())
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)

            Text(app.localizedName ?? id)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 4)

            if privacy.isCloaked && selected {
                Button(visible ? "Hide again" : "Show") {
                    if visible {
                        privacy.hideAgain(id)
                    } else {
                        privacy.revealTemporarily(id)
                    }
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help(visible ? "Hide this app again" : "Temporarily show this app")
            }
        }
        .frame(height: 40)
        .contentShape(Rectangle())
    }

    private var actionArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                privacy.toggleMeetingMode()
            } label: {
                Label(
                    privacy.isCloaked ? "Restore protected apps" : "Hide protected apps",
                    systemImage: privacy.isCloaked ? "lock.open" : "eye.slash"
                )
                .frame(maxWidth: .infinity)
                .frame(height: 24)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: [])

            HStack {
                Text("Shortcut")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("⌃ ⌥ ⌘ H")
                    .monospaced()
            }
            .font(.caption)

            if privacy.isCloaked && !privacy.temporarilyVisibleIDs.isEmpty {
                Label("\(privacy.temporarilyVisibleIDs.count) temporarily visible", systemImage: "eye")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Text(privacy.status)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var footer: some View {
        HStack {
            Text("Window-hiding prototype")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
