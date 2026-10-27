import SwiftUI
import SwiftData

struct WorkoutsView: View {
    @Query(sort: \Workout.createdAt) private var workouts: [Workout]
    @State private var showNew = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    WeekStrip(days: Set(workouts.flatMap { $0.weekdays })).cardStyle()

                    if workouts.isEmpty {
                        ContentUnavailableView("Нет тренировок",
                                               systemImage: "dumbbell",
                                               description: Text("Нажми +, чтобы добавить свою, или сгенерируй тяжёлую программу во вкладке «Профиль»."))
                            .padding(.top, 40)
                    } else {
                        ForEach(workouts) { w in
                            NavigationLink { WorkoutDetailView(workout: w) } label: { WorkoutCard(workout: w) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Theme.bg)
            .navigationTitle("bycreep")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: { Image(systemName: "plus.circle.fill").font(.title3) }
                }
            }
            .sheet(isPresented: $showNew) { WorkoutEditView(workout: nil) }
        }
    }
}

struct WorkoutCard: View {
    let workout: Workout
    var body: some View {
        let today = Shared.weekdayIndex(Date())
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(workout.name).font(.headline).foregroundStyle(.white)
                Text(workout.weekdays.sorted().map { Shared.dayLabels[$0] }.joined(separator: " · ").ifEmpty("без дня"))
                    .font(.subheadline).foregroundStyle(Theme.gray)
                Text("\(workout.exercises.count) упр.").font(.caption).foregroundStyle(Theme.gray)
            }
            Spacer()
            if workout.weekdays.contains(today) {
                Text("СЕГОДНЯ").font(.system(size: 11, weight: .heavy))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.red, in: Capsule())
            }
            Image(systemName: "chevron.right").foregroundStyle(Theme.gray)
        }
        .cardStyle()
    }
}

private extension String {
    func ifEmpty(_ s: String) -> String { isEmpty ? s : self }
}

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let workout: Workout
    @State private var showEdit = false
    @State private var showSession = false
    @State private var confirmDelete = false

    var body: some View {
        List {
            Section {
                ForEach(workout.sortedExercises) { e in
                    HStack {
                        Text(e.name)
                        Spacer()
                        Text("\(e.sets)×\(e.reps)" + (e.weight > 0 ? " · \(e.weight.formatted()) кг" : ""))
                            .foregroundStyle(Theme.gray)
                            .monospacedDigit()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Изменить", systemImage: "pencil") { showEdit = true }
                    Button("Удалить", systemImage: "trash", role: .destructive) { confirmDelete = true }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button { showSession = true } label: {
                Text("Начать тренировку").font(.headline)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Theme.red, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16).padding(.bottom, 8)
        }
        .sheet(isPresented: $showEdit) { WorkoutEditView(workout: workout) }
        .fullScreenCover(isPresented: $showSession) { WorkoutSessionView(workout: workout) }
        .confirmationDialog("Удалить тренировку?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                ctx.delete(workout)
                Sync.widget(ctx)
                dismiss()
            }
        }
    }
}

struct WorkoutEditView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let workout: Workout?
    @State private var name: String
    @State private var days: Set<Int>
    @State private var drafts: [ExDraft]

    init(workout: Workout?) {
        self.workout = workout
        _name = State(initialValue: workout?.name ?? "")
        _days = State(initialValue: Set(workout?.weekdays ?? []))
        _drafts = State(initialValue: workout?.sortedExercises.map {
            ExDraft(name: $0.name, sets: $0.sets, reps: $0.reps, weight: $0.weight)
        } ?? [ExDraft()])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Название") { TextField("Например: Грудь + трицепс", text: $name) }
                Section("Дни недели") { DayPicker(selection: $days).padding(.vertical, 4) }
                Section("Упражнения") {
                    ForEach($drafts) { $d in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Упражнение", text: $d.name)
                                .font(.headline)
                            Stepper("Подходы: \(d.sets)", value: $d.sets, in: 1...12)
                            Stepper("Повторения: \(d.reps)", value: $d.reps, in: 1...100)
                            HStack {
                                Text("Вес, кг")
                                TextField("0", value: $d.weight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { drafts.remove(atOffsets: $0) }
                    .onMove { drafts.move(fromOffsets: $0, toOffset: $1) }

                    Button { drafts.append(ExDraft()) } label: {
                        Label("Добавить упражнение", systemImage: "plus")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle(workout == nil ? "Новая тренировка" : "Изменить")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDone()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let w: Workout
        if let workout {
            w = workout
            for e in w.exercises { ctx.delete(e) }
            w.exercises = []
        } else {
            w = Workout(name: name)
            ctx.insert(w)
        }
        w.name = name.trimmingCharacters(in: .whitespaces)
        w.weekdays = days.sorted()
        for (i, d) in drafts.enumerated() where !d.name.trimmingCharacters(in: .whitespaces).isEmpty {
            let e = Exercise(name: d.name, sets: d.sets, reps: d.reps, weight: d.weight, order: i)
            ctx.insert(e)
            e.workout = w
        }
        Sync.widget(ctx)
        dismiss()
    }
}

struct WorkoutSessionView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let workout: Workout
    @State private var done: [PersistentIdentifier: Int] = [:]
    @State private var start = Date()

    private var exercises: [Exercise] { workout.sortedExercises }
    private var totalSets: Int { exercises.reduce(0) { $0 + $1.sets } }
    private var doneSets: Int { done.values.reduce(0, +) }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ProgressView(value: Double(doneSets), total: Double(max(totalSets, 1)))
                        .tint(Theme.red)
                    ForEach(exercises) { ex in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(ex.name).font(.headline)
                            Text("\(ex.sets)×\(ex.reps)" + (ex.weight > 0 ? " · \(ex.weight.formatted()) кг" : ""))
                                .font(.subheadline).foregroundStyle(Theme.gray)
                            HStack(spacing: 10) {
                                ForEach(0..<ex.sets, id: \.self) { i in
                                    let isOn = (done[ex.persistentModelID] ?? 0) > i
                                    Button {
                                        let cur = done[ex.persistentModelID] ?? 0
                                        done[ex.persistentModelID] = cur > i ? i : i + 1
                                    } label: {
                                        Text("\(i + 1)")
                                            .font(.system(size: 15, weight: .bold))
                                            .frame(width: 40, height: 40)
                                            .background(isOn ? Theme.red : Color.white.opacity(0.08), in: Circle())
                                            .foregroundStyle(.white)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .cardStyle()
                    }
                }
                .padding(16)
            }
            .background(Theme.bg)
            .sensoryFeedback(.impact, trigger: doneSets)
            .navigationTitle(workout.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Выйти") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Завершить", action: finish).bold() }
            }
        }
    }

    private func finish() {
        let minutes = max(1, Int(Date().timeIntervalSince(start) / 60))
        ctx.insert(WorkoutLog(date: Date(), workoutName: workout.name, setsDone: doneSets, minutes: minutes))
        try? ctx.save()
        Shared.markDone()
        dismiss()
    }
}
