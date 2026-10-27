import SwiftUI
import WidgetKit

/// Общий слой приложения и виджета (App Group, лёгкий UserDefaults — без тяжёлой БД в виджете).
enum Shared {
    static let group = "group.com.bycreep.app"
    private static let trainingKey = "trainingWeekdays"
    private static let doneKey = "doneDays"
    static let dayLabels = ["пн", "вт", "ср", "чт", "пт", "сб", "вс"]

    private static var defaults: UserDefaults { UserDefaults(suiteName: group) ?? .standard }

    /// Неделя с понедельника
    static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }

    /// 0 = пн … 6 = вс
    static func weekdayIndex(_ date: Date) -> Int {
        (calendar.component(.weekday, from: date) + 5) % 7
    }

    static var trainingDays: Set<Int> {
        Set((defaults.array(forKey: trainingKey) as? [Int]) ?? [])
    }

    static func setTrainingDays(_ days: Set<Int>) {
        defaults.set(days.sorted(), forKey: trainingKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func markDone(_ date: Date = Date()) {
        let day = calendar.startOfDay(for: date).timeIntervalSince1970
        var list = (defaults.array(forKey: doneKey) as? [Double]) ?? []
        if !list.contains(day) { list.append(day) }
        defaults.set(Array(list.suffix(60)), forKey: doneKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func doneThisWeek(_ date: Date = Date()) -> Set<Int> {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        let list = (defaults.array(forKey: doneKey) as? [Double]) ?? []
        return Set(list.map { Date(timeIntervalSince1970: $0) }
            .filter { week.contains($0) }
            .map { weekdayIndex($0) })
    }
}

enum Palette {
    static let red = Color(red: 1.0, green: 0.12, blue: 0.18)
}

/// Кружок дня недели. Используется и в приложении, и в виджете.
struct DayDot: View {
    let label: String
    let isTraining: Bool
    let isToday: Bool
    let isDone: Bool

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                if isTraining {
                    Circle().fill(Palette.red)
                        .shadow(color: Palette.red.opacity(0.9), radius: 7)
                } else {
                    Circle().fill(Color.white.opacity(0.06))
                    Circle().stroke(Color.white.opacity(0.8), lineWidth: 2)
                }
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 30, height: 30)
            .overlay {
                if isToday { Circle().stroke(Color.white, lineWidth: 1).padding(-4) }
            }
            Text(label)
                .font(.system(size: 12, weight: isToday ? .heavy : .medium))
                .foregroundStyle(.white)
        }
    }
}
