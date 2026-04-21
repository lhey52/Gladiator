//
//  ReminderNotifications.swift
//  Gladiator
//

import Foundation
import UserNotifications

enum ReminderNotifications {
    static func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    static func schedule(id: String, title: String, body: String, at date: Date) async {
        cancel(id: id)

        guard date > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = title.isEmpty ? "Reminder" : title
        if !body.isEmpty {
            content.body = body
        }
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Ignore scheduling errors — the reminder still persists without a notification.
        }
    }

    static func cancel(id: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [id])
    }
}
