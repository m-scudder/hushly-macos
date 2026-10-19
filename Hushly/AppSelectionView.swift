import AppKit
import SwiftUI

struct AppSelectionView: View {
    @EnvironmentObject private var privacy: PrivacyController
    @StateObject private var login = LoginItemController()
    @State private var showOnlyProtected = false

    private var visibleApps: [ProtectedApp] {
        privacy.appCatalog.filter { !showOnlyProtected || privacy.protectedIDs.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().padding(.vertical, 12)
            appHeader
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(visibleApps) { app in appRow(app) }
                }
            }
            .frame(height: min(CGFloat(max(visibleApps.count, 1)) * 40, 240))
            .padding(.top, 5)
            Divider().padding(.vertical, 12)
            actionArea
            Divider().padding(.vertical, 12)
            settings
            Divider().padding(.vertical, 12)
            footer
        }
        .padding(16)
        .frame(width: 360)
    }

    private var header: some View {
        HStack(spacing: 9) {
            Image(systemName: "eye.slash").font(.system(size: 20, weight: .semibold)).frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text("Hushly").font(.headline)
                Text("Keep personal apps out of meetings").font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(privacy.isCloaked ? "HIDDEN" : "READY")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(privacy.isCloaked ? Color.orange : Color.secondary)
        }
    }

    private var appHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("APPS").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text("\(privacy.protectedIDs.count) selected").font(.caption).foregroundStyle(.tertiary)
                Spacer()
                Button { privacy.addInstalledApps() } label: {
                    Label("Add app", systemImage: "plus").font(.caption)
                }
                .buttonStyle(.plain)
                Button { privacy.refreshRunningApps() } label: {
                    Image(systemName: "arrow.clockwise").font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Refresh running apps")
            }
            HStack {
                Toggle("Protected only", isOn: $showOnlyProtected)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                Spacer()
                Text("Saved apps remain listed when closed")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func appRow(_ app: ProtectedApp) -> some View {
        let selected = privacy.protectedIDs.contains(app.id)
        let visible = privacy.temporarilyVisibleIDs.contains(app.id)
        return HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { privacy.protectedIDs.contains(app.id) },
                set: { _ in privacy.toggleProtection(app.id) }
            ))
            .labelsHidden().toggleStyle(.checkbox).frame(width: 18)
            Image(nsImage: app.icon).resizable().scaledToFit().frame(width: 22, height: 22)
            Text(app.name).font(.system(size: 13)).lineLimit(1)
            if !app.isRunning {
                Text("Not running").font(.system(size: 10)).foregroundStyle(.tertiary)
            }
            Spacer(minLength: 4)
            if privacy.isCloaked && selected && app.isRunning {
                Button(visible ? "Hide again" : "Show") {
                    if visible { privacy.hideAgain(app.id) }
                    else { privacy.revealTemporarily(app.id) }
                }
                .font(.caption).buttonStyle(.bordered).controlSize(.small)
            }
        }
        .frame(height: 40)
    }

    private var actionArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { privacy.toggleMeetingMode() } label: {
                Label(privacy.isCloaked ? "Restore protected apps" : "Hide protected apps",
                      systemImage: privacy.isCloaked ? "lock.open" : "eye.slash")
                    .frame(maxWidth: .infinity).frame(height: 24)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: [])
            HStack {
                Text("Shortcut").foregroundStyle(.secondary)
                Spacer()
                Text("⌃ ⌥ ⌘ H").monospaced()
            }
            .font(.caption)
            if privacy.isCloaked && !privacy.temporarilyVisibleIDs.isEmpty {
                Label("\(privacy.temporarilyVisibleIDs.count) temporarily visible", systemImage: "eye")
                    .font(.caption).foregroundStyle(.orange)
            }
            Text(privacy.status).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 5) {
            Toggle("Launch at Login", isOn: Binding(
                get: { login.isEnabled },
                set: { login.setEnabled($0) }
            ))
            .font(.system(size: 13))
            .onAppear { login.refresh() }
            if let error = login.errorMessage {
                Text(error).font(.caption2).foregroundStyle(.orange)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("Window-hiding prototype").font(.caption2).foregroundStyle(.tertiary)
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
        }
    }
}
