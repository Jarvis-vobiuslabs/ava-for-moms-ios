import SwiftUI

struct GroceryView: View {

    @State private var checked: Set<String> = ["Strawberries", "Whole milk"]

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ────────────────────────────────────────────
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bi-Rite · pickup 2 PM")
                                .font(AvaTheme.font(13, weight: .bold))
                                .foregroundStyle(AvaTheme.inkMute)
                            Text("Grocery 🛒")
                                .font(AvaTheme.font(28, weight: .heavy))
                                .foregroundStyle(AvaTheme.ink)
                                .tracking(-0.6)
                        }
                        Spacer()
                        VStack(spacing: 2) {
                            Text("\(checkedCount)/\(totalCount)")
                                .font(AvaTheme.font(18, weight: .heavy))
                                .foregroundStyle(.white)
                            Text("items")
                                .font(AvaTheme.font(10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 16).fill(AvaTheme.sage))
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 60)
                    .padding(.bottom, 14)

                    // ── Ava suggestion ────────────────────────────────────
                    HStack(spacing: 12) {
                        Circle()
                            .fill(AvaTheme.blushTerracotta)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "face.smiling")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                        Text("I added orzo + feta — for the Greek chicken you wanted to try 💡")
                            .font(AvaTheme.font(13, weight: .medium))
                            .foregroundStyle(.white)
                            .lineSpacing(2)
                        Spacer()
                        Button(action: {}) {
                            Text("OK")
                                .font(AvaTheme.font(11.5, weight: .heavy))
                                .foregroundStyle(AvaTheme.terracottaDeep)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .background(AvaTheme.blushTerracotta)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)

                    // ── Sections ──────────────────────────────────────────
                    ForEach(grocerySections) { section in
                        grocerySection(section)
                    }

                    Spacer().frame(height: 130)
                }
            }
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    private var checkedCount: Int { checked.count }
    private var totalCount: Int { grocerySections.flatMap(\.items).count }

    private func grocerySection(_ section: GrocerySection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(section.title)
                .font(AvaTheme.font(14, weight: .heavy))
                .foregroundStyle(AvaTheme.ink)
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                ForEach(Array(section.items.enumerated()), id: \.offset) { idx, item in
                    let isDone = checked.contains(item.name)
                    Button {
                        if isDone { checked.remove(item.name) }
                        else       { checked.insert(item.name) }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .strokeBorder(isDone ? AvaTheme.sage : AvaTheme.inkSoft, lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                if isDone {
                                    Circle().fill(AvaTheme.sage).frame(width: 24, height: 24)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(AvaTheme.font(14.5, weight: .bold))
                                    .foregroundStyle(isDone ? AvaTheme.inkSoft : AvaTheme.ink)
                                    .strikethrough(isDone, color: AvaTheme.inkSoft)
                                if let tag = item.tag {
                                    Text("for \(tag)")
                                        .font(AvaTheme.font(11, weight: .bold))
                                        .foregroundStyle(AvaTheme.terracotta)
                                }
                            }
                            Spacer()
                            Text(item.qty)
                                .font(AvaTheme.font(13, weight: .semibold))
                                .foregroundStyle(AvaTheme.inkMute)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .opacity(isDone ? 0.45 : 1)
                        .background(AvaTheme.cream)
                    }
                    .buttonStyle(.plain)

                    if idx < section.items.count - 1 {
                        Divider().padding(.leading, 52).tint(AvaTheme.line)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .padding(.horizontal, 18)
        }
    }

    // ── Data ────────────────────────────────────────────────────────────

    private struct GroceryItem {
        let name: String
        let qty: String
        let tag: String?
    }

    private struct GrocerySection: Identifiable {
        let id = UUID()
        let title: String
        let items: [GroceryItem]
    }

    private let grocerySections: [GrocerySection] = [
        GrocerySection(title: "🥬 Produce", items: [
            GroceryItem(name: "Lemons",       qty: "3",       tag: "dinner"),
            GroceryItem(name: "Baby spinach", qty: "1 bag",   tag: "dinner"),
            GroceryItem(name: "Strawberries", qty: "2 boxes", tag: "Mia's snack"),
            GroceryItem(name: "Garlic",       qty: "1 head",  tag: nil),
        ]),
        GrocerySection(title: "🍞 Pantry", items: [
            GroceryItem(name: "Olive oil",    qty: "1 bottle",tag: nil),
            GroceryItem(name: "Orzo",         qty: "1 box",   tag: "dinner"),
        ]),
        GrocerySection(title: "🧀 Dairy", items: [
            GroceryItem(name: "Whole milk",   qty: "1 gal",   tag: nil),
            GroceryItem(name: "Feta",         qty: "1 block", tag: nil),
        ]),
    ]
}

#Preview {
    GroceryView()
}
