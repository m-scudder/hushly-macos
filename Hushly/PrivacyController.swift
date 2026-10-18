import AppKit
import LocalAuthentication

@MainActor
final class PrivacyController: ObservableObject {
    @Published private(set) var isCloaked = false
    @Published private(set) var status = "Choose running apps to protect."
    @Published var protectedIDs: Set<String> {
        didSet { UserDefaults.standard.set(Array(protectedIDs), forKey: Self.defaultsKey) }
    }
    @Published private(set) var runningApps: [NSRunningApplication] = []
    @Published private(set) var temporarilyVisibleIDs: Set<String> = []

    private static let defaultsKey = "protectedBundleIdentifiers"
    private var enforcementTimer: Timer?
    private var observer: NSObjectProtocol?
    private var restoring = false

    init() {
        protectedIDs = Set(UserDefaults.standard.stringArray(forKey: Self.defaultsKey) ?? [])
        refreshRunningApps()
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshRunningApps()
                self?.enforceHiddenIfNeeded()
            }
        }
    }

    func refreshRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications
            .filter { app in
                app.bundleIdentifier != Bundle.main.bundleIdentifier &&
                app.activationPolicy == .regular &&
                app.bundleIdentifier != nil
            }
            .sorted { ($0.localizedName ?? "").localizedCaseInsensitiveCompare($1.localizedName ?? "") == .orderedAscending }
    }

    func toggleProtection(_ id: String) {
        if protectedIDs.contains(id) {
            protectedIDs.remove(id)
        } else {
            protectedIDs.insert(id)
        }
        // Unprotected apps are no longer subject to the meeting-mode guard.
        temporarilyVisibleIDs.remove(id)
        if isCloaked { enforceHiddenIfNeeded() }
    }

    /// Explicitly allow one protected app on screen while other protected apps stay hidden.
    /// The exception only lasts for the current meeting-mode session.
    func revealTemporarily(_ id: String) {
        guard isCloaked, protectedIDs.contains(id) else { return }
        temporarilyVisibleIDs.insert(id)
        for app in NSWorkspace.shared.runningApplications where app.bundleIdentifier == id {
            _ = app.unhide()
            _ = app.activate(options: [.activateIgnoringOtherApps])
        }
        status = "Allowed this app on screen. Hide it again before sharing private content."
    }

    func hideAgain(_ id: String) {
        guard isCloaked, protectedIDs.contains(id) else { return }
        temporarilyVisibleIDs.remove(id)
        enforceHiddenIfNeeded()
        status = "App protected again."
    }

    func toggleMeetingMode() {
        if isCloaked {
            restoreWithAuthentication()
        } else {
            cloak()
        }
    }

    func cloak() {
        guard !protectedIDs.isEmpty else {
            status = "Select at least one app first."
            return
        }
        temporarilyVisibleIDs.removeAll()
        isCloaked = true
        enforceHiddenIfNeeded()
        enforcementTimer?.invalidate()
        enforcementTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.enforceHiddenIfNeeded() }
        }
        status = "Meeting mode enabled. Hidden windows are not a security boundary."
    }

    private func enforceHiddenIfNeeded() {
        guard isCloaked else { return }
        for app in NSWorkspace.shared.runningApplications {
            guard let id = app.bundleIdentifier, protectedIDs.contains(id), !app.isHidden else { continue }
            _ = app.hide()
        }
        // Never claim complete protection: macOS can re-show windows between checks.
    }

    private func restoreWithAuthentication() {
        guard !restoring else { return }
        restoring = true
        let context = LAContext()
        var error: NSError?
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
            ? .deviceOwnerAuthentication
            : .deviceOwnerAuthenticationWithBiometrics

        context.evaluatePolicy(policy, localizedReason: "Restore your protected applications") { [weak self] success, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.restoring = false
                if success { self.restore() }
                else { self.status = "Authentication cancelled or unavailable; apps remain hidden." }
            }
        }
    }

    private func restore() {
        enforcementTimer?.invalidate()
        enforcementTimer = nil
        isCloaked = false
        temporarilyVisibleIDs.removeAll()
        for app in NSWorkspace.shared.runningApplications {
            if let id = app.bundleIdentifier, protectedIDs.contains(id) {
                _ = app.unhide()
            }
        }
        status = "Personal apps restored."
    }

    deinit {
        enforcementTimer?.invalidate()
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
}
