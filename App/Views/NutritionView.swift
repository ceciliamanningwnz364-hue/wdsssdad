import SwiftUI
import SwiftData

struct NutritionView: View {
    @State private var day = Date()
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Text(day, format: .dateTime.weekday(.wide).day().month())
                        .font(.headline)
                    Spacer()
                    Button { shift(1) } label: { Image(systemName: "chevron.right") }
                }
                .padding(.horizontal, 20).padding(.vertical, 8)

                NutritionDayView(day: day)
            }
            .background(Theme.bg)
            .navigationTitle("Питание")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus.circle.fill").font(.title3) }
                }
            }
            .sheet(isPresented: $showAdd) { AddFoodView(day: day) }
        }
    }

    private func shift(_ d: Int) {
        day = Calendar.current.date(byAdding: .day, value: d, to: day) ?? day
    }
}

struct NutritionDayView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var items: [FoodEntry]
    @AppStorage("weight") private var weight = 80.0
    @AppStorage("height") private var height = 180.0
    @AppStorage("age") private var age = 25
    @AppStorage("isMale") private var isMale = true
    @AppStorage("activity") private var activity = 1.55
    @AppStorage("goal") private var goal = 1

    init(day: Date) {
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        _items = Query(filter: #Predicate<FoodEntry> { $0.date >= start && $0.date < end },
                       sort: [SortDescriptor(\.date)])
    }

    var body: some View {
        let t = Targets.make(weight: weight, height: height, age: age, male: isMale, activity: activity, goal: goal)
        let kcal = items.reduce(0) { $0 + $1.kcal }
        let p = items.reduce(0) { $0 + $1.protein }
        let f = items.reduce(0) { $0 + $1.fat }
        let c = items.reduce(0) { $0 + $1.carbs }

        List {
            Section {
                SummaryCard(kcal: kcal, p: p, f: f, c: c, t: t)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            ForEach(0..<4, id: \.self) { m in
                let list = items.filter { $0.meal == m }
                if !list.isEmpty {
                    Section(Meals.names[m]) {
                        ForEach(list) { e in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(e.name)
                                    Text("Б \(Int(e.protein)) · Ж \(Int(e.fat)) · У \(Int(e.carbs))")
                                        .font(.caption).foregroundStyle(Theme.gray)
                                }
                                Spacer()
                                Text("\(e.kcal) ккал").monospacedDigit().foregroundStyle(Theme.gray)
                            }
                        }
                        .onDelete { idx in
                            for i in idx { ctx.delete(list[i]) }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
}

struct SummaryCard: View {
    let kcal: Int
    let p: Double
    let f: Double
    let c: Double
    let t: Targets

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.1), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: min(1, Double(kcal) / Double(max(t.kcal, 1))))
                    .stroke(Theme.red, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(kcal)").font(.title2.bold()).monospacedDigit()
                    Text("из \(t.kcal)").font(.caption).foregroundStyle(Theme.gray)
                }
            }
            .frame(width: 110, height: 110)

            VStack(spacing: 10) {
                bar("Белки", p, Double(t.protein))
                bar("Жиры", f, Double(t.fat))
                bar("Углеводы", c, Double(t.carbs))
            }
        }
        .cardStyle()
    }

    private func bar(_ title: String, _ v: Double, _ goal: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption)
                Spacer()
                Text("\(Int(v))/\(Int(goal)) г").font(.caption).foregroundStyle(Theme.gray).monospacedDigit()
            }
            ProgressView(value: min(v, max(goal, 1)), total: max(goal, 1)).tint(Theme.red)
        }
    }
}

struct AddFoodView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let day: Date
    @Query private var recent: [FoodEntry]

    @State private var name = ""
    @State private var meal = 0
    @State private var kcal = 0
    @State private var protein = 0.0
    @State private var fat = 0.0
    @State private var carbs = 0.0

    init(day: Date) {
        self.day = day
        var d = FetchDescriptor<FoodEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        d.fetchLimit = 40
        _recent = Query(d)
    }

    private var uniqueRecent: [FoodEntry] {
        var seen = Set<String>()
        return recent.filter { seen.insert($0.name.lowercased()).inserted }.prefix(8).map { $0 }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Приём пищи") {
                    Picker("Приём", selection: $meal) {
                        ForEach(0..<4, id: \.self) { Text(Meals.names[$0]).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    TextField("Название", text: $name)
                }
                if !uniqueRecent.isEmpty {
                    Section("Недавние") {
                        ForEach(uniqueRecent) { r in
                            Button {
                                name = r.name; kcal = r.kcal
                                protein = r.protein; fat = r.fat; carbs = r.carbs
                            } label: {
                                HStack { Text(r.name); Spacer(); Text("\(r.kcal) ккал").foregroundStyle(Theme.gray) }
                            }
                            .tint(.white)
                        }
                    }
                }
                Section("Пищевая ценность") {
                    row("Калории, ккал", Binding(get: { Double(kcal) }, set: { kcal = Int($0) }))
                    row("Белки, г", $protein)
                    row("Жиры, г", $fat)
                    row("Углеводы, г", $carbs)
                    Text("Если калории = 0, посчитаю по БЖУ.").font(.caption).foregroundStyle(Theme.gray)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Добавить еду")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDone()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить", action: save).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func row(_ title: String, _ value: Binding<Double>) -> some View {
        HStack {
            Text(title)
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }

    private func save() {
        let cal = Calendar.current
        let date = cal.isDateInToday(day) ? Date() : (cal.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day)
        let k = kcal > 0 ? kcal : Int((protein * 4 + carbs * 4 + fat * 9).rounded())
        ctx.insert(FoodEntry(date: date, name: name.trimmingCharacters(in: .whitespaces),
                             meal: meal, kcal: k, protein: protein, fat: fat, carbs: carbs))
        try? ctx.save()
        dismiss()
    }
}
