//
//  NotificationManager.swift
//  green04
//
//  Created by Karina Kazbekova on 08.04.2026.
//


// 📁 NotificationManager.swift
import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    private let notificationId = "mood_check_daily"
    
    // ⏰ Три времени для уведомлений (настройте под себя)
    private let notificationTimes: [NotificationTime] = [
        .init(hour: 9, minute: 0, label: "morning"),    // 09:00
        .init(hour: 14, minute: 0, label: "afternoon"), // 14:00
        .init(hour: 19, minute: 38, label: "evening")    // 20:00
    ]
    
    private init() { }
    
    // ✅ Запрос разрешения на уведомления
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
    
    // ✅ Регистрация делегата для обработки тапа по уведомлению
    private func registerNotificationDelegate() async {
        let delegate = NotificationDelegate.shared
        center.delegate = delegate
    }
    
    // ✅ Планирование 3 ежедневных уведомлений
    func scheduleDailyNotifications() async {
        let settings = await center.notificationSettings()
        let authorized = settings.authorizationStatus == .authorized
        guard authorized else {
            print("⚠️ Notifications not authorized")
            return
        }
        
        // Удаляем старые, чтобы не дублировать
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
                print("✅ Scheduled: \(time.label) at \(time.hour):\(time.minute)")
            } catch {
                print("❌ Failed to schedule \(time.label): \(error)")
            }
        }
    }
    
    // ✅ Отмена всех уведомлений
    func cancelAllNotifications() async {
        await center.removePendingNotificationRequests(withIdentifiers: [
            notificationId + "_morning",
            notificationId + "_afternoon",
            notificationId + "_evening"
        ])
        print("🗑️ Cancelled all mood notifications")
    }
    
    // ✅ Проверка, включены ли уведомления
    func areNotificationsEnabled() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}

// 🕐 Вспомогательная структура
private struct NotificationTime {
    let hour: Int
    let minute: Int
    let label: String
}

// 🎯 Делегат для обработки тапа по уведомлению
@MainActor
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // Обработка тапа, когда приложение в фоне/закрыто
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        handleNotificationTap(userInfo: userInfo)
        completionHandler()
    }
    
    // Обработка, когда приложение на переднем плане
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Показываем уведомление даже если приложение активно
        completionHandler([.banner, .sound])
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // 📢 Здесь можно отправить сигнал в приложение, чтобы открыть экран настроения
        NotificationCenter.default.post(name: .moodNotificationTapped, object: nil, userInfo: userInfo)
    }
}

// 📡 Notification Name для общения между слоями
extension Notification.Name {
    static let moodNotificationTapped = Notification.Name("moodNotificationTapped")
}
