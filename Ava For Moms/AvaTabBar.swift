import SwiftUI

enum AvaTab: String {
    case home, chat, calendar, tasks, grocery
}

struct AvaTabBar: View {
    @Binding var selected: AvaTab

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.home,     symbol: "house.fill",            label: "Today")
            tabButton(.calendar, symbol: "calendar",              label: "Calendar")
            avaButton
            tabButton(.tasks,    symbol: "checkmark.square.fill", label: "To-do")
            tabButton(.grocery,  symbol: "cart.fill",             label: "List")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(AvaTheme.cream)
                .shadow(color: AvaTheme.ink.opacity(0.12), radius: 14, x: 0, y: 8)
        )
        .padding(.horizontal, 14)
    }

    @ViewBuilder
    private func tabButton(_ tab: AvaTab, symbol: String, label: String) -> some View {
        let on = selected == tab
        Button { selected = tab } label: {
            VStack(spacing: 2) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: on ? .bold : .regular))
                    .frame(height: 26)
                Text(label)
                    .font(AvaTheme.font(10, weight: .bold))
            }
            .foregroundStyle(on ? AvaTheme.terracotta : AvaTheme.inkSoft)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var avaButton: some View {
        let on = selected == .chat
        return Button { selected = .chat } label: {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(AvaTheme.blushTerracotta)
                        .frame(width: 36, height: 36)
                        .shadow(color: AvaTheme.terracotta.opacity(0.4), radius: 6, x: 0, y: 4)
                    Image(systemName: "face.smiling")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text("Ava")
                    .font(AvaTheme.font(10, weight: .bold))
                    .foregroundStyle(on ? AvaTheme.terracotta : AvaTheme.inkSoft)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AvaTabBar(selected: .constant(.home))
        .padding()
        .background(Color.gray.opacity(0.1))
}
