
import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    private let notificationId = "mood_check_daily"
    
    private let notificationTimes: [NotificationTime] = [
        .init(hour: 9, minute: 0, label: "morning"),    // 09:00
        .init(hour: 14, minute: 0, label: "afternoon"), // 14:00
        .init(hour: 19, minute: 38, label: "evening")    // 20:00
    ]
    
    private init() { }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                await registerNotificationDelegate()
            }
            return granted
        } catch {
            print("Notification auth error: \(error)")
            return false
        }
    }
    
    private func registerNotificationDelegate() async {
        let delegate = NotificationDelegate.shared
        center.delegate = delegate
    }
    
    func scheduleDailyNotifications() async {
        let settings = await center.notificationSettings()
        let authorized = settings.authorizationStatus == .authorized
        guard authorized else {
            print("Notifications not authorized")
            return
        }
        
        await center.removePendingNotificationRequests(withIdentifiers: [notificationId])
        
        for time in notificationTimes {
            let content = UNMutableNotificationContent()
            content.title = "Mood Check"
            content.body = "How's your mood today?"
            content.sound = .default
            content.userInfo = ["source": "mood_app", "time": time.label]
            
            var dateComponents = DateComponents()
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute
            dateComponents.timeZone = TimeZone.current
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "\(notificationId)_\(time.label)", content: content, trigger: trigger)
            
            do {
                try await center.add(request)
                print("Scheduled: \(time.label) at \(time.hour):\(time.minute)")
            } catch {
                print("Failed to schedule \(time.label): \(error)")
            }
        }
    }
    
    func cancelAllNotifications() async {
        await center.removePendingNotificationRequests(withIdentifiers: [
            notificationId + "_morning",
            notificationId + "_afternoon",
            notificationId + "_evening"
        ])
        print("Cancelled all mood notifications")
    }
    
    func areNotificationsEnabled() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}

private struct NotificationTime {
    let hour: Int
    let minute: Int
    let label: String
}

@MainActor
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        handleNotificationTap(userInfo: userInfo)
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.banner, .sound])
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        NotificationCenter.default.post(name: .moodNotificationTapped, object: nil, userInfo: userInfo)
    }
}

extension Notification.Name {
    static let moodNotificationTapped = Notification.Name("moodNotificationTapped")
}
