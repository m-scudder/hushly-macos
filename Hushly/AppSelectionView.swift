import AppKit
import SwiftUI

struct AppSelectionView: View {
    @EnvironmentObject private var privacy: PrivacyController

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Hushly", systemImage: "eye.slash")
                    .font(.title3.bold())
                Spacer()
                Text(privacy.isCloaked ? "MEETING MODE" : "READY")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(privacy.isCloaked ? .orange : .secondary)
            }

            Text("Hide personal app windows before sharing your screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Text("Protected running apps")
                    .font(.headline)
                Spacer()
                Button {
                    privacy.refreshRunningApps()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh running applications")
            }

            ScrollView {
                LazyVStack(spacing: 3) {
                    ForEach(privacy.runningApps, id: \.processIdentifier) { app in
                        if let identifier = app.bundleIdentifier {
                            Toggle(isOn: Binding(
                                get: { privacy.protectedIDs.contains(identifier) },
                                set: { _ in privacy.toggleProtection(identifier) }
                            )) {
                                HStack(spacing: 8) {
                                    Image(nsImage: app.icon ?? NSImage())
                                        .resizable()
                                        .frame(width: 21, height: 21)
                                    Text(app.localizedName ?? identifier)
                                        .lineLimit(1)
                                }
                            }
                            .toggleStyle(.checkbox)
                            if privacy.isCloaked && privacy.protectedIDs.contains(identifier) {
                                Button(privacy.temporarilyVisibleIDs.contains(identifier) ? "Hide again" : "Show") {
                                    if privacy.temporarilyVisibleIDs.contains(identifier) {
                                        privacy.hideAgain(identifier)
                                    } else {
                                        privacy.revealTemporarily(identifier)
                                    }
                                }
                                .font(.caption)
                                .help("Temporarily allow this app during meeting mode")
                            }
                            Divider()
                                .opacity(0.35)
                        }
                    }
                }
            }
            .frame(height: 190)

            Button {
                privacy.toggleMeetingMode()
            } label: {
                Label(privacy.isCloaked ? "Restore with Touch ID / password" : "Hide protected apps",
                      systemImage: privacy.isCloaked ? "lock.open" : "eye.slash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: [])

            Text("Shortcut: ⌃⌥⌘H  •  \(privacy.protectedIDs.count) selected")
                .font(.caption)
                .foregroundStyle(.secondary)
            if privacy.isCloaked && !privacy.temporarilyVisibleIDs.isEmpty {
                Text("\(privacy.temporarilyVisibleIDs.count) app(s) temporarily visible during meeting mode")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.orange)
            }
            Text(privacy.status)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
            HStack {
                Text("Prototype • Windows only")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(16)
        .frame(width: 360)
    }
}
