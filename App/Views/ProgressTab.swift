import SwiftUI
import SwiftData
import PhotosUI

struct ProgressTab: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \ProgressPhoto.date, order: .reverse) private var photos: [ProgressPhoto]
    @AppStorage("weight") private var weight = 80.0

    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var selected: [PersistentIdentifier] = []
    @State private var compare: [ProgressPhoto]?
    @State private var opened: ProgressPhoto?

    private let cols = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    header
                    HStack(spacing: 10) {
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Label("Галерея", systemImage: "photo.on.rectangle").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button { showCamera = true } label: {
                                Label("Камера", systemImage: "camera.fill").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .controlSize(.large)

                    if photos.isEmpty {
                        ContentUnavailableView("Пока нет фото", systemImage: "camera",
                                               description: Text("Делай фото раз в месяц — сравнишь прогресс."))
                    } else {
                        Text("Выбери два фото, чтобы сравнить").font(.footnote).foregroundStyle(Theme.gray)
                        LazyVGrid(columns: cols, spacing: 6) {
                            ForEach(photos) { p in cell(p) }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle("Прогресс")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сравнить") {
                        compare = photos.filter { selected.contains($0.persistentModelID) }
                            .sorted { $0.date < $1.date }
                    }
                    .disabled(selected.count != 2)
                }
            }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) { await add(data) }
                    pickerItem = nil
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { img in
                    if let d = img.jpegData(compressionQuality: 0.9) { Task { await add(d) } }
                }
                .ignoresSafeArea()
            }
            .sheet(item: $opened) { PhotoDetail(photo: $0) }
            .sheet(isPresented: Binding(get: { compare != nil }, set: { if !$0 { compare = nil } })) {
                if let c = compare, c.count == 2 { CompareView(a: c[0], b: c[1]) }
            }
        }
    }

    private var header: some View {
        let days = photos.first.map { Calendar.current.dateComponents([.day], from: $0.date, to: Date()).day ?? 0 }
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Фото прогресса").font(.headline)
                if let days {
                    Text(days >= 30 ? "Последнее \(days) дн. назад — пора сделать новое" : "Последнее \(days) дн. назад")
                        .font(.subheadline)
                        .foregroundStyle(days >= 30 ? Theme.red : Theme.gray)
                } else {
                    Text("Сделай первое фото — это точка старта").font(.subheadline).foregroundStyle(Theme.gray)
                }
            }
            Spacer()
        }
        .cardStyle()
    }

    private func cell(_ p: ProgressPhoto) -> some View {
        let isSel = selected.contains(p.persistentModelID)
        return Color.clear
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .overlay { StoredImage(fileName: p.fileName, maxPixel: 400) }
            .overlay(alignment: .bottomLeading) {
                Text(p.date, format: .dateTime.day().month(.abbreviated).year(.twoDigits))
                    .font(.system(size: 10, weight: .bold))
                    .padding(4).background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 4))
                    .padding(4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.red, lineWidth: isSel ? 3 : 0)
            }
            .onTapGesture {
                if isSel { selected.removeAll { $0 == p.persistentModelID } }
                else if selected.count < 2 { selected.append(p.persistentModelID) }
            }
            .contextMenu {
                Button("Открыть", systemImage: "arrow.up.left.and.arrow.down.right") { opened = p }
                Button("Удалить", systemImage: "trash", role: .destructive) {
                    selected.removeAll { $0 == p.persistentModelID }
                    ImageStore.delete(p.fileName)
                    ctx.delete(p)
                }
            }
    }

    private func add(_ data: Data) async {
        let name = await Task.detached(priority: .utility) { ImageStore.save(data) }.value
        guard let name else { return }
        ctx.insert(ProgressPhoto(date: Date(), fileName: name, weight: weight))
        try? ctx.save()
    }
}

struct PhotoDetail: View {
    @Environment(\.dismiss) private var dismiss
    let photo: ProgressPhoto
    var body: some View {
        NavigationStack {
            VStack {
                StoredImage(fileName: photo.fileName, maxPixel: 1600, fill: false)
                Text("\(photo.date.formatted(date: .long, time: .omitted)) · \(photo.weight.formatted()) кг")
                    .font(.subheadline).foregroundStyle(Theme.gray).padding()
            }
            .background(Theme.bg)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Закрыть") { dismiss() } } }
        }
    }
}

struct CompareView: View {
    @Environment(\.dismiss) private var dismiss
    let a: ProgressPhoto   // раньше
    let b: ProgressPhoto   // позже

    var body: some View {
        let days = Calendar.current.dateComponents([.day], from: a.date, to: b.date).day ?? 0
        let dw = b.weight - a.weight
        NavigationStack {
            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    column(a, "ДО")
                    column(b, "ПОСЛЕ")
                }
                HStack(spacing: 24) {
                    stat("Период", "\(days) дн.")
                    stat("Вес", (dw >= 0 ? "+" : "") + dw.formatted(.number.precision(.fractionLength(1))) + " кг")
                }
                .cardStyle()
                Spacer()
            }
            .padding(16)
            .background(Theme.bg)
            .navigationTitle("Сравнение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } } }
        }
    }

    private func column(_ p: ProgressPhoto, _ title: String) -> some View {
        VStack(spacing: 6) {
            Color.clear.aspectRatio(3.0 / 4.0, contentMode: .fit)
                .overlay { StoredImage(fileName: p.fileName, maxPixel: 900) }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text(title).font(.system(size: 12, weight: .heavy)).foregroundStyle(Theme.red)
            Text(p.date, format: .dateTime.day().month().year()).font(.caption).foregroundStyle(Theme.gray)
            Text("\(p.weight.formatted()) кг").font(.subheadline.bold())
        }
    }

    private func stat(_ t: String, _ v: String) -> some View {
        VStack(alignment: .leading) {
            Text(t).font(.caption).foregroundStyle(Theme.gray)
            Text(v).font(.title3.bold())
        }
    }
}
