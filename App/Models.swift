import Foundation
import SwiftData

@Model final class Workout {
    var name: String
    var weekdays: [Int]          // 0 = пн … 6 = вс
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Exercise.workout)
    var exercises: [Exercise] = []

    init(name: String, weekdays: [Int] = [], createdAt: Date = Date()) {
        self.name = name
        self.weekdays = weekdays
        self.createdAt = createdAt
    }

    var sortedExercises: [Exercise] { exercises.sorted { $0.order < $1.order } }
}

@Model final class Exercise {
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double
    var order: Int
    var workout: Workout?

    init(name: String, sets: Int, reps: Int, weight: Double, order: Int) {
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.order = order
    }
}

@Model final class WorkoutLog {
    var date: Date
    var workoutName: String
    var setsDone: Int
    var minutes: Int

    init(date: Date, workoutName: String, setsDone: Int, minutes: Int) {
        self.date = date
        self.workoutName = workoutName
        self.setsDone = setsDone
        self.minutes = minutes
    }
}

@Model final class ProgressPhoto {
    var date: Date
    var fileName: String
    var weight: Double
    var note: String

    init(date: Date, fileName: String, weight: Double, note: String = "") {
        self.date = date
        self.fileName = fileName
        self.weight = weight
        self.note = note
    }
}

@Model final class BodyEntry {
    var date: Date
    var weight: Double
    var chest: Double   // 0 = не указано
    var waist: Double
    var arm: Double

    init(date: Date = Date(), weight: Double, chest: Double = 0, waist: Double = 0, arm: Double = 0) {
        self.date = date
        self.weight = weight
        self.chest = chest
        self.waist = waist
        self.arm = arm
    }
}

@Model final class FoodEntry {
    var date: Date
    var name: String
    var meal: Int       // 0 завтрак, 1 обед, 2 ужин, 3 перекус
    var kcal: Int
    var protein: Double
    var fat: Double
    var carbs: Double

    init(date: Date, name: String, meal: Int, kcal: Int, protein: Double, fat: Double, carbs: Double) {
        self.date = date
        self.name = name
        self.meal = meal
        self.kcal = kcal
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
    }
}

enum Meals { static let names = ["Завтрак", "Обед", "Ужин", "Перекус"] }

/// Синхронизация дней тренировок в виджет
enum Sync {
    static func widget(_ ctx: ModelContext) {
        try? ctx.save()
        let all = (try? ctx.fetch(FetchDescriptor<Workout>())) ?? []
        Shared.setTrainingDays(Set(all.flatMap { $0.weekdays }))
    }
}
