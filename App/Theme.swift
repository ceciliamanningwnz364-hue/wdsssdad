import SwiftUI

enum Theme {
    static let bg = Color.black
    static let card = Color(white: 0.09)
    static let card2 = Color(white: 0.14)
    static let red = Palette.red
    static let gray = Color(white: 0.55)
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }

    func keyboardDone() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                    to: nil, from: nil, for: nil)
                }
            }
        }
    }
}
