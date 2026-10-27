import Foundation

struct ExDraft: Identifiable, Hashable {
    var id = UUID()
    var name = ""
    var sets = 3
    var reps = 10
    var weight: Double = 0
}

struct DayDraft: Identifiable {
    let id = UUID()
    var name: String
    var weekday: Int
    var exercises: [ExDraft]
}

enum Level: Int, CaseIterable {
    case beginner, intermediate, advanced
    var title: String { ["Новичок", "Средний", "Продвинутый"][rawValue] }
    var mult: Double { [0.6, 1.0, 1.25][rawValue] }
}

/// Генератор тяжёлых тренировок: база 5×5 / 4×6, рабочие веса считаются от массы тела, пола и уровня.
enum PlanGenerator {
    struct Move { let name: String; let coef: Double }
    typealias Item = (move: Move, sets: Int, reps: Int)

    static let squat = Move(name: "Присед со штангой", coef: 1.0)
    static let bench = Move(name: "Жим лёжа", coef: 0.8)
    static let deadlift = Move(name: "Становая тяга", coef: 1.25)
    static let ohp = Move(name: "Жим стоя", coef: 0.5)
    static let row = Move(name: "Тяга штанги в наклоне", coef: 0.7)
    static let pullups = Move(name: "Подтягивания", coef: 0)
    static let dips = Move(name: "Отжимания на брусьях", coef: 0)
    static let rdl = Move(name: "Румынская тяга", coef: 0.9)
    static let legPress = Move(name: "Жим ногами", coef: 1.6)
    static let inclineDB = Move(name: "Жим гантелей на наклонной (1 гантель)", coef: 0.3)
    static let pulldown = Move(name: "Тяга верхнего блока", coef: 0.7)
    static let curl = Move(name: "Подъём штанги на бицепс", coef: 0.35)
    static let pushdown = Move(name: "Разгибания на трицепс (блок)", coef: 0.4)
    static let lateral = Move(name: "Махи гантелей в стороны (1 гантель)", coef: 0.1)
    static let legCurl = Move(name: "Сгибания ног лёжа", coef: 0.5)
    static let calf = Move(name: "Подъём на носки", coef: 1.0)
    static let hipThrust = Move(name: "Ягодичный мост со штангой", coef: 1.2)
    static let facePull = Move(name: "Тяга к лицу (блок)", coef: 0.3)

    static func template(_ key: String) -> (String, [Item]) {
        switch key {
        case "push": return ("Грудь / плечи / трицепс", [(bench, 5, 5), (ohp, 4, 6), (inclineDB, 3, 8), (dips, 3, 8), (pushdown, 3, 10), (lateral, 3, 12)])
        case "pull": return ("Спина / бицепс", [(deadlift, 3, 5), (row, 4, 6), (pullups, 4, 6), (pulldown, 3, 8), (facePull, 3, 12), (curl, 3, 8)])
        case "legs": return ("Ноги", [(squat, 5, 5), (rdl, 4, 6), (legPress, 3, 8), (legCurl, 3, 10), (calf, 4, 12)])
        case "upper": return ("Верх тела", [(bench, 5, 5), (row, 5, 5), (ohp, 3, 6), (pullups, 3, 6), (curl, 3, 8), (pushdown, 3, 8)])
        case "lower": return ("Низ тела", [(squat, 5, 5), (deadlift, 3, 5), (hipThrust, 3, 8), (legCurl, 3, 8), (calf, 4, 10)])
        case "fullA": return ("Всё тело A", [(squat, 5, 5), (bench, 5, 5), (row, 4, 6), (curl, 2, 8)])
        case "fullB": return ("Всё тело B", [(deadlift, 3, 5), (ohp, 4, 6), (pullups, 4, 6), (pushdown, 2, 10)])
        default: return ("Всё тело C", [(squat, 4, 6), (bench, 4, 6), (pulldown, 4, 8), (lateral, 3, 12)])
        }
    }

    static func make(weight: Double, male: Bool, level: Level, days: Int) -> [DayDraft] {
        let keys: [(String, Bool)]   // (шаблон, объёмный день?)
        let weekdays: [Int]
        switch days {
        case ...3: keys = [("fullA", false), ("fullB", false), ("fullC", false)]; weekdays = [0, 2, 4]
        case 4: keys = [("upper", false), ("lower", false), ("upper", true), ("lower", true)]; weekdays = [0, 1, 3, 4]
        case 5: keys = [("push", false), ("pull", false), ("legs", false), ("upper", true), ("lower", true)]; weekdays = [0, 1, 3, 4, 5]
        default: keys = [("push", false), ("pull", false), ("legs", false), ("push", true), ("pull", true), ("legs", true)]; weekdays = [0, 1, 2, 3, 4, 5]
        }
        let sexMult = male ? 1.0 : 0.65

        return zip(keys, weekdays).map { pair, wd in
            let (key, volume) = pair
            let (title, items) = template(key)
            let exs: [ExDraft] = items.map { item in
                var sets = item.sets
                var reps = item.reps
                var w = weight * item.move.coef * level.mult * sexMult
                if level == .beginner { sets = max(3, sets - 1) }
                if volume { reps += 3; w *= 0.85 }
                w = (w / 2.5).rounded() * 2.5
                return ExDraft(name: item.move.name, sets: sets, reps: reps, weight: max(0, w))
            }
            return DayDraft(name: volume ? "\(title) (объём)" : title, weekday: wd, exercises: exs)
        }
    }
}
