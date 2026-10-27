import SwiftUI
import UIKit

struct WeekStrip: View {
    let days: Set<Int>
    var body: some View {
        let today = Shared.weekdayIndex(Date())
        let done = Shared.doneThisWeek()
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                DayDot(label: Shared.dayLabels[i], isTraining: days.contains(i),
                       isToday: i == today, isDone: done.contains(i))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 6)
    }
}

/// Выбор дней недели при редактировании тренировки
struct DayPicker: View {
    @Binding var selection: Set<Int>
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                let on = selection.contains(i)
                Button {
                    if on { selection.remove(i) } else { selection.insert(i) }
                } label: {
                    Text(Shared.dayLabels[i])
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 38, height: 38)
                        .background(on ? Theme.red : Color.white.opacity(0.08), in: Circle())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

/// Ленивая загрузка фото с диска (ImageIO + кэш)
struct StoredImage: View {
    let fileName: String
    var maxPixel: Int = 400
    var fill = true
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: fill ? .fill : .fit)
            } else {
                Theme.card2
            }
        }
        .task(id: fileName) { image = await ImageStore.load(fileName, maxPixel: maxPixel) }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = .camera
        p.delegate = context.coordinator
        return p
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ p: CameraPicker) { parent = p }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.onImage(img) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
