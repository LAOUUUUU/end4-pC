import Foundation
import UserNotifications

/// Posts a notification when the track changes. The system asks for permission the first time.
@MainActor
final class TrackNotifier {
    func post(title: String, artist: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = artist
            center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
    }
}
