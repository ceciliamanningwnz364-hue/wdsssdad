import SwiftUI
import SwiftData
import Charts

struct ProfileView: View {
    @Query(sort: \BodyEntry.date) private var entries: [BodyEntry]

    @AppStorage("weight") private var weight = 80.0
    @AppStorage("height") private var height = 180.0
    @AppStorage("age") private var age = 25
    @AppStorage("isMale") private var isMale = true
    @AppStorage("level") private var level = 1
    @AppStorage("activity") private var activity = 1.55
    @AppStorage("goal") private var goal = 1
    @AppStorage("daysPerWeek") private var daysPerWeek = 4
    @AppStorage("photoReminder") private var photoReminder = false

    @State private var showLog = false

    var body: some View {
        let t = Targets.make(weight: weight, height: height, age: age, male: isMale, activity: activity, goal: goal)
        let bmi = weight / pow(height / 100, 2)

        NavigationStack {
            Form {
                Section("Параметры") {
                    Picker("Пол", selection: $isMale) {
                        Text("Мужской").tag(true)
                        Text("Женский").tag(false)
                    }
                    .pickerStyle(.segmented)
                    numRow("Рост, см", $height)
                    Stepper("Возраст: \(age)", value: $age, in: 14...80)
                    Picker("Уровень", selection: $level) {
                        ForEach(Level.allCases, id: \.rawValue) { Text($0.title).tag($0.rawValue) }
                    }
                    Picker("Активность", selection: $activity) {
                        Text("Сидячая").tag(1.2)
                        Text("1–3 тренировки/нед").tag(1.375)
                        Text("3–5 тренировок/нед").tag(1.55)
                        Text("6–7 тренировок/нед").tag(1.725)
                    }
                    Picker("Цель", selection: $goal) {
                        Text("Сушка").tag(0)
                        Text("Поддержание").tag(1)
                        Text("Набор массы").tag(2)
                    }
                    Stepper("Тренировок в неделю: \(daysPerWeek)", value: $daysPerWeek, in: 3...6)
                }

                Section("Вес") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(weight.formatted()) кг").font(.title2.bold())
                            Text("ИМТ \(bmi.formatted(.number.precision(.fractionLength(1))))")
                                .font(.caption).foregroundStyle(Theme.gray)
                        }
                        Spacer()
                        Button("Записать") { showLog = true }.buttonStyle(.borderedProminent)
                    }
                    if entries.count >= 2 {
                        Chart(entries) { e in
                            LineMark(x: .value("Дата", e.date), y: .value("кг", e.weight))
                                .foregroundStyle(Theme.red)
                                .interpolationMethod(.monotone)
                            PointMark(x: .value("Дата", e.date), y: .value("кг", e.weight))
                                .foregroundStyle(Theme.red)
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .frame(height: 150)
                    }
                }

                Section("Норма на день") {
                    LabeledContent("Калории", value: "\(t.kcal) ккал")
                    LabeledContent("Белки", value: "\(t.protein) г")
                    LabeledContent("Жиры", value: "\(t.fat) г")
                    LabeledContent("Углеводы", value: "\(t.carbs) г")
                }

                Section {
                    NavigationLink {
                        GeneratorView()
                    } label: {
                        Label("Сгенерировать тяжёлую программу", systemImage: "bolt.fill")
                    }
                    Toggle("Напоминать о фото (1-го числа)", isOn: $photoReminder)
                        .onChange(of: photoReminder) { _, on in Reminders.setPhotoReminder(on) }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Профиль")
            .keyboardDone()
            .sheet(isPresented: $showLog) { LogBodyView() }
        }
    }

    private func numRow(_ title: String, _ value: Binding<Double>) -> some View {
        HStack {
            Text(title)
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct LogBodyView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @AppStorage("weight") private var storedWeight = 80.0
    @State private var weight = 0.0
    @State private var chest = 0.0
    @State private var waist = 0.0
    @State private var arm = 0.0

    var body: some View {
        NavigationStack {
            Form {
                Section("Сегодня") {
                    row("Вес, кг", $weight)
                }
                Section("Замеры, см (необязательно)") {
                    row("Грудь", $chest)
                    row("Талия", $waist)
                    row("Рука (бицепс)", $arm)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Замеры")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDone()
            .onAppear { weight = storedWeight }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        ctx.insert(BodyEntry(weight: weight, chest: chest, waist: waist, arm: arm))
                        storedWeight = weight
                        try? ctx.save()
                        dismiss()
                    }
                    .disabled(weight <= 0)
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
}

struct GeneratorView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @AppStorage("weight") private var weight = 80.0
    @AppStorage("isMale") private var isMale = true
    @AppStorage("level") private var level = 1
    @AppStorage("daysPerWeek") private var daysPerWeek = 4
    @State private var plan: [DayDraft] = []

    var body: some View {
        List {
            Section {
                Text("Тяжёлая силовая программа под твои параметры: база 5×5 / 4×6, веса рассчитаны от массы тела (\(weight.formatted()) кг), уровня и пола. Это стартовая оценка — начни с разминочных подходов и подстрой веса под себя.")
                    .font(.footnote).foregroundStyle(Theme.gray)
            }
            ForEach(plan) { d in
                Section("\(Shared.dayLabels[d.weekday].uppercased()) · \(d.name)") {
                    ForEach(d.exercises) { e in
                        HStack {
                            Text(e.name)
                            Spacer()
                            Text("\(e.sets)×\(e.reps)" + (e.weight > 0 ? " · \(e.weight.formatted()) кг" : ""))
                                .foregroundStyle(Theme.gray).monospacedDigit()
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Тяжёлая программа")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if plan.isEmpty { regenerate() } }
        .safeAreaInset(edge: .bottom) {
            Button(action: addAll) {
                Text("Добавить в мои тренировки").font(.headline)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Theme.red, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16).padding(.bottom, 8)
        }
    }

    private func regenerate() {
        plan = PlanGenerator.make(weight: weight, male: isMale,
                                  level: Level(rawValue: level) ?? .intermediate, days: daysPerWeek)
    }

    private func addAll() {
        for d in plan {
            let w = Workout(name: d.name, weekdays: [d.weekday])
            ctx.insert(w)
            for (i, e) in d.exercises.enumerated() {
                let ex = Exercise(name: e.name, sets: e.sets, reps: e.reps, weight: e.weight, order: i)
                ctx.insert(ex)
                ex.workout = w
            }
        }
        Sync.widget(ctx)
        dismiss()
    }
}
