import Foundation
import UserNotifications

struct Targets {
    var kcal: Int
    var protein: Int
    var fat: Int
    var carbs: Int

    /// Mifflin–St Jeor. goal: 0 сушка, 1 поддержание, 2 набор
    static func make(weight: Double, height: Double, age: Int, male: Bool,
                     activity: Double, goal: Int) -> Targets {
        let bmr = 10 * weight + 6.25 * height - 5 * Double(age) + (male ? 5 : -161)
        let factor = goal == 0 ? 0.85 : (goal == 2 ? 1.10 : 1.0)
        let kcal = bmr * activity * factor
        let protein = weight * 2.0
        let fat = weight * 0.9
        let carbs = max(0, (kcal - protein * 4 - fat * 9) / 4)
        return Targets(kcal: Int(kcal.rounded()), protein: Int(protein.rounded()),
                       fat: Int(fat.rounded()), carbs: Int(carbs.rounded()))
    }
}

enum Reminders {
    /// Напоминание о фото прогресса: 1-го числа каждого месяца в 10:00
    static func setPhotoReminder(_ on: Bool) {
        let c = UNUserNotificationCenter.current()
        c.removePendingNotificationRequests(withIdentifiers: ["photo"])
        guard on else { return }
        c.requestAuthorization(options: [.alert, .sound]) { ok, _ in
            guard ok else { return }
            var dc = DateComponents()
            dc.day = 1
            dc.hour = 10
            let content = UNMutableNotificationContent()
            content.title = "bycreep"
            content.body = "Пора сделать фото прогресса 📸"
            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            c.add(UNNotificationRequest(identifier: "photo", content: content, trigger: trigger))
        }
    }
}
