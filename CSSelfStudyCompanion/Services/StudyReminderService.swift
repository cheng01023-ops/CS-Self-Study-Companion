import Foundation
import UserNotifications

@MainActor
enum StudyReminderService {
    static let enabledKey = "studyReminderEnabled"
    static let hourKey = "studyReminderHour"
    static let minuteKey = "studyReminderMinute"
    static let notificationID = "daily-study-reminder"

    static func refreshFromDefaults() async {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: enabledKey) else {
            cancel()
            return
        }
        let hour = defaults.object(forKey: hourKey) as? Int ?? 20
        let minute = defaults.object(forKey: minuteKey) as? Int ?? 0
        _ = await schedule(hour: hour, minute: minute)
    }

    static func setEnabled(_ enabled: Bool, hour: Int, minute: Int) async -> Bool {
        let defaults = UserDefaults.standard
        defaults.set(enabled, forKey: enabledKey)
        defaults.set(hour, forKey: hourKey)
        defaults.set(minute, forKey: minuteKey)

        if enabled {
            return await schedule(hour: hour, minute: minute)
        }

        cancel()
        return true
    }

    static func schedule(hour: Int, minute: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound]) { success, _ in
                continuation.resume(returning: success)
            }
        }
        guard granted else { return false }

        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        let content = UNMutableNotificationContent()
        content.title = "今天学一点 CS"
        content.body = "打开今日计划，完成一个小步骤。稳定积累比一次学很久更有效。"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)

        return await withCheckedContinuation { continuation in
            center.add(request) { error in
                continuation.resume(returning: error == nil)
            }
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}
