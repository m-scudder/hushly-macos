import AppKit
import LocalAuthentication
import UniformTypeIdentifiers

struct ProtectedApp: Identifiable {
    let id: String
    let name: String
    let icon: NSImage
    let isRunning: Bool
}

@MainActor
final class PrivacyController: ObservableObject {
    @Published private(set) var isCloaked = false
    @Published private(set) var status = "Choose apps to protect."
    @Published var protectedIDs: Set<String> {
        didSet { UserDefaults.standard.set(Array(protectedIDs), forKey: Self.defaultsKey); rebuildCatalog() }
    }
    @Published private(set) var runningApps: [NSRunningApplication] = []
    @Published private(set) var appCatalog: [ProtectedApp] = []
    @Published private(set) var temporarilyVisibleIDs: Set<String> = []

    private static let defaultsKey = "protectedBundleIdentifiers"
    private var enforcementTimer: Timer?
    private var observers: [NSObjectProtocol] = []
    private var restoring = false

    init() {
        protectedIDs = Set(UserDefaults.standard.stringArray(forKey: Self.defaultsKey) ?? [])
        refreshRunningApps()
        for event in [NSWorkspace.didLaunchApplicationNotification,
                      NSWorkspace.didTerminateApplicationNotification] {
            let token = NSWorkspace.shared.notificationCenter.addObserver(
                forName: event, object: nil, queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshRunningApps()
                    self?.enforceHiddenIfNeeded()
                }
            }
            observers.append(token)
        }
    }

    func refreshRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier != Bundle.main.bundleIdentifier &&
            $0.activationPolicy == .regular && $0.bundleIdentifier != nil
        }
        rebuildCatalog()
    }

    private func rebuildCatalog() {
        // Keep saved bundle identifiers in the list even if their apps are not running.
        var catalog: [String: ProtectedApp] = [:]
        for app in runningApps {
            guard let id = app.bundleIdentifier else { continue }
            catalog[id] = ProtectedApp(id: id, name: app.localizedName ?? id,
                                        icon: app.icon ?? NSImage(), isRunning: true)
        }
        for id in protectedIDs where catalog[id] == nil {
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id)
            let name = url.map { FileManager.default.displayName(atPath: $0.path) } ?? id
            let icon = url.map { NSWorkspace.shared.icon(forFile: $0.path) } ?? NSImage()
            catalog[id] = ProtectedApp(id: id, name: name, icon: icon, isRunning: false)
        }
        appCatalog = catalog.values.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    func addInstalledApps() {
        let panel = NSOpenPanel()
        panel.title = "Choose applications to protect"
        panel.message = "Select one or more .app bundles."
        panel.allowedContentTypes = [UTType.applicationBundle]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        guard panel.runModal() == .OK else { return }
        var added = 0
        for url in panel.urls {
            guard let bundle = Bundle(url: url), let id = bundle.bundleIdentifier,
                  id != Bundle.main.bundleIdentifier else { continue }
            protectedIDs.insert(id)
            added += 1
        }
        status = added > 0 ? "Saved \(added) app(s) to your protected list." : "No valid applications selected."
        if isCloaked { enforceHiddenIfNeeded() }
    }

    func toggleProtection(_ id: String) {
        if protectedIDs.contains(id) { protectedIDs.remove(id) }
        else { protectedIDs.insert(id) }
        temporarilyVisibleIDs.remove(id)
        if isCloaked { enforceHiddenIfNeeded() }
    }

    func revealTemporarily(_ id: String) {
        guard isCloaked, protectedIDs.contains(id) else { return }
        temporarilyVisibleIDs.insert(id)
        for app in NSWorkspace.shared.runningApplications where app.bundleIdentifier == id {
            _ = app.unhide()
            _ = app.activate(options: [.activateIgnoringOtherApps])
        }
        status = "App temporarily visible. Hide it again when finished."
    }

    func hideAgain(_ id: String) {
        guard isCloaked, protectedIDs.contains(id) else { return }
        temporarilyVisibleIDs.remove(id)
        enforceHiddenIfNeeded()
        status = "App protected again."
    }

    func toggleMeetingMode() {
        if isCloaked { restoreWithAuthentication() }
        else { cloak() }
    }

    func cloak() {
        guard !protectedIDs.isEmpty else { status = "Select at least one app first."; return }
        temporarilyVisibleIDs.removeAll()
        isCloaked = true
        enforceHiddenIfNeeded()
        enforcementTimer?.invalidate()
        enforcementTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.enforceHiddenIfNeeded() }
        }
        status = "Meeting mode on. Window hiding is not a security boundary."
    }

    private func enforceHiddenIfNeeded() {
        guard isCloaked else { return }
        for app in NSWorkspace.shared.runningApplications {
            guard let id = app.bundleIdentifier,
                  protectedIDs.contains(id),
                  !temporarilyVisibleIDs.contains(id),
                  !app.isHidden else { continue }
            _ = app.hide()
        }
    }

    private func restoreWithAuthentication() {
        guard !restoring else { return }
        restoring = true
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthentication,
                               localizedReason: "Restore your protected applications") { [weak self] success, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.restoring = false
                if success { self.restore() }
                else { self.status = "Authentication cancelled or unavailable." }
            }
        }
    }

    private func restore() {
        enforcementTimer?.invalidate()
        enforcementTimer = nil
        isCloaked = false
        temporarilyVisibleIDs.removeAll()
        for app in NSWorkspace.shared.runningApplications {
            if let id = app.bundleIdentifier, protectedIDs.contains(id) { _ = app.unhide() }
        }
        status = "Personal apps restored."
    }

    deinit {
        enforcementTimer?.invalidate()
        for observer in observers { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
    }
}
