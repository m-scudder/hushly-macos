import ServiceManagement
import SwiftUI

@MainActor
final class LoginItemController: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var errorMessage: String?

    init() { refresh() }

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        errorMessage = nil
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            errorMessage = "Launch at Login could not be updated: \(error.localizedDescription)"
        }
        refresh()
    }
}
