
import UserNotifications
import NotificationCenter
import SwiftUI

struct NotificationSettingsView: View {
    @State private var isEnabled: Bool = false
    @State private var times: [TimeSlots] = [
        .init(label: "Morning", time: "09:00", active: true),
        .init(label: "Afternoon", time: "14:00", active: true),
        .init(label: "Evening", time: "20:00", active: true)
    ]
    
    var body: some View {
        Form {
            Section(header: Text("Daily Reminders")) {
                Toggle("Enable mood reminders", isOn: $isEnabled)
                    .onChange(of: isEnabled) { newValue in
                        Task {
                            if newValue {
                                _ = await NotificationManager.shared.requestAuthorization()
                                await NotificationManager.shared.scheduleDailyNotifications()
                            } else {
                                await NotificationManager.shared.cancelAllNotifications()
                            }
                        }
                    }
            }
            
            Section(header: Text("Reminder Times")) {
                ForEach($times) { $time in
                    HStack {
                        Text(time.label)
                        Spacer()
                        Toggle("", isOn: $time.active)
                            .labelsHidden()
                    }
                }
            }
            
            Section {
                Button("Test Notification") {
                    sendTestNotification()
                }
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("Notifications")
        .onAppear {
            Task {
                isEnabled = await NotificationManager.shared.areNotificationsEnabled()
            }
        }
    }
    
    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test"
        content.body = "This is a test notification!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "test", content: content, trigger: trigger)
        
        Task {
            try? await UNUserNotificationCenter.current().add(request)
        }
    }
}

struct TimeSlots: Identifiable {
    let id = UUID()
    let label: String
    let time: String
    var active: Bool
}
