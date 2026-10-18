import SwiftUI

@main
struct HushlyApp: App {
    @StateObject private var privacy = PrivacyController()
    @StateObject private var hotkey = HotkeyManager()

    var body: some Scene {
        MenuBarExtra {
            AppSelectionView()
                .environmentObject(privacy)
                .onAppear {
                    hotkey.onToggle = { [weak privacy] in
                        Task { @MainActor in privacy?.toggleMeetingMode() }
                    }
                    hotkey.register()
                }
        } label: {
            Image(systemName: privacy.isCloaked ? "eye.slash.fill" : "eye")
                .accessibilityLabel(privacy.isCloaked ? "Hushly: meeting mode" : "Hushly")
        }
        .menuBarExtraStyle(.window)
    }
}
