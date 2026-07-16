import SwiftUI

struct GroceryView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(GroceryStore.self) private var store
    @State private var showAddItem = false
    @State private var newItemName = ""

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ────────────────────────────────────────────
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Grocery 🛒")
                                .font(AvaTheme.font(28, weight: .heavy)).foregroundStyle(AvaTheme.ink).tracking(-0.6)
                        }
                        Spacer()
                        // Item count badge
                        if !store.items.isEmpty {
                            VStack(spacing: 2) {
                                Text("\(store.unchecked.count)/\(store.items.count)")
                                    .font(AvaTheme.font(16, weight: .heavy)).foregroundStyle(.white)
                                Text("left").font(AvaTheme.font(10, weight: .bold)).foregroundStyle(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 16).fill(AvaTheme.sage))
                        }
                    }
                    .padding(.horizontal, 22).padding(.top, 60).padding(.bottom, 16)

                    // ── Add item row ──────────────────────────────────────
                    HStack(spacing: 12) {
                        TextField("Add an item…", text: $newItemName)
                            .font(AvaTheme.font(15, weight: .medium)).foregroundStyle(AvaTheme.ink)
                            .submitLabel(.done)
                            .onSubmit { addItem() }
                        if !newItemName.isEmpty {
                            Button(action: addItem) {
                                Circle().fill(AvaTheme.blushTerracotta).frame(width: 32, height: 32)
                                    .overlay(Image(systemName: "arrow.up")
                                        .font(.system(size: 13, weight: .bold)).foregroundStyle(.white))
                            }
                            .contentShape(Rectangle())
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(AvaTheme.cream))
                    .padding(.horizontal, 18).padding(.bottom, 14)
                    .animation(.easeInOut(duration: 0.15), value: newItemName.isEmpty)

                    // ── Empty state ───────────────────────────────────────
                    if store.items.isEmpty && !store.isLoading {
                        VStack(spacing: 12) {
                            Text("🛒").font(.system(size: 36))
                            Text("List is empty")
                                .font(AvaTheme.font(17, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                            Text("Type above to add items, or ask Ava to add them for you.")
                                .font(AvaTheme.font(14, weight: .medium)).foregroundStyle(AvaTheme.inkMute)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 50).padding(.horizontal, 40)
                    }

                    // ── Sections ──────────────────────────────────────────
                    ForEach(store.sections, id: \.title) { section in
                        grocerySection(title: section.title, items: section.items)
                    }

                    // ── Clear checked button ──────────────────────────────
                    if !store.checked.isEmpty {
                        Button {
                            _Concurrency.Task { await store.clearChecked() }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash").font(.system(size: 13, weight: .semibold))
                                Text("Clear \(store.checked.count) checked")
                                    .font(AvaTheme.font(14, weight: .semibold))
                            }
                            .foregroundStyle(AvaTheme.inkMute)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AvaTheme.line, lineWidth: 1.5))
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain).padding(.horizontal, 18).padding(.top, 8)
                    }

                    Spacer().frame(height: 130)
                }
            }
        }
        .task {
            if let userId = auth.currentUserId { await store.load(userId: userId) }
        }
    }

    // MARK: - Section

    private func grocerySection(title: String, items: [GroceryListItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(AvaTheme.font(14, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                .padding(.horizontal, 24).padding(.top, 14).padding(.bottom, 10)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                    itemRow(item, isLast: idx == items.count - 1)
                }
            }
            .background(RoundedRectangle(cornerRadius: 22).fill(AvaTheme.cream))
            .padding(.horizontal, 18)
        }
    }

    private func itemRow(_ item: GroceryListItem, isLast: Bool) -> some View {
        HStack(spacing: 12) {
            Button {
                _Concurrency.Task { await store.toggle(item) }
            } label: {
                ZStack {
                    Circle().strokeBorder(item.checked ? AvaTheme.sage : AvaTheme.inkSoft, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if item.checked {
                        Circle().fill(AvaTheme.sage).frame(width: 24, height: 24)
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                    }
                }
            }
            .contentShape(Rectangle())
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(AvaTheme.font(14.5, weight: .bold))
                    .foregroundStyle(item.checked ? AvaTheme.inkSoft : AvaTheme.ink)
                    .strikethrough(item.checked, color: AvaTheme.inkSoft)
                if let tag = item.tag {
                    Text("for \(tag)").font(AvaTheme.font(11, weight: .bold)).foregroundStyle(AvaTheme.terracotta)
                }
            }
            Spacer()
            if let qty = item.quantity {
                Text(qty).font(AvaTheme.font(13, weight: .semibold)).foregroundStyle(AvaTheme.inkMute)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .opacity(item.checked ? 0.5 : 1)
        .overlay(alignment: .bottom) {
            if !isLast { Divider().padding(.leading, 52).tint(AvaTheme.line) }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                _Concurrency.Task { await store.remove(item) }
            } label: { Label("Remove", systemImage: "trash") }
        }
    }

    // MARK: - Add

    private func addItem() {
        let name = newItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, let userId = auth.currentUserId else { return }
        newItemName = ""
        _Concurrency.Task { await store.add(name: name, userId: userId) }
    }
}

#Preview {
    GroceryView().environment(AuthManager()).environment(GroceryStore())
}
