import Foundation
import ServiceManagement
import UserNotifications

/// macOS notifications, respecting the Settings toggle.
enum SystemNotifications {
    private static var available: Bool { Bundle.main.bundleIdentifier != nil } // not under `swift run`

    static func requestAccess() {
        guard available else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func post(_ title: String, _ body: String) {
        guard available, Preferences.notify else { return }
        let c = UNMutableNotificationContent()
        c.title = title
        c.body = body
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: nil))
    }
}

enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }
    static func set(_ on: Bool) throws {
        if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
    }
}

/// User preferences (written by the Settings window via @AppStorage with the same keys).
enum Preferences {
    static var autoConnect: Bool { UserDefaults.standard.object(forKey: "autoConnect") as? Bool ?? true }
    static var notify: Bool { UserDefaults.standard.object(forKey: "notify") as? Bool ?? true }
    static var retrySeconds: Double { UserDefaults.standard.object(forKey: "retrySeconds") as? Double ?? 10 }
}
