import WidgetKit
import SwiftUI

struct WeekEntry: TimelineEntry {
    let date: Date
    let training: Set<Int>
    let done: Set<Int>
}

struct WeekProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeekEntry {
        WeekEntry(date: Date(), training: [0, 2, 4], done: [0])
    }

    func getSnapshot(in context: Context, completion: @escaping (WeekEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeekEntry>) -> Void) {
        // Обновляемся один раз в сутки, сразу после полуночи — минимум батареи
        let next = Shared.calendar.nextDate(after: Date(),
                                            matching: DateComponents(hour: 0, minute: 1),
                                            matchingPolicy: .nextTime)
            ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [makeEntry()], policy: .after(next)))
    }

    private func makeEntry() -> WeekEntry {
        WeekEntry(date: Date(), training: Shared.trainingDays, done: Shared.doneThisWeek())
    }
}

struct WeekWidgetView: View {
    let entry: WeekEntry

    var body: some View {
        let today = Shared.weekdayIndex(entry.date)
        let trainsToday = entry.training.contains(today)

        VStack(spacing: 14) {
            HStack {
                Text("BYCREEP")
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(.white)
                Spacer()
                Text(trainsToday ? "Сегодня тренировка" : "Сегодня отдых")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(trainsToday ? Palette.red : Color.white.opacity(0.55))
            }
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    DayDot(label: Shared.dayLabels[i],
                           isTraining: entry.training.contains(i),
                           isToday: i == today,
                           isDone: entry.done.contains(i))
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .containerBackground(Color.black, for: .widget)
    }
}

@main
struct BycreepWidget: Widget {
    let kind = "BycreepWeek"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeekProvider()) { entry in
            WeekWidgetView(entry: entry)
        }
        .configurationDisplayName("bycreep · неделя")
        .description("Дни тренировок. Тренировочный день горит красным.")
        .supportedFamilies([.systemMedium])
    }
}
