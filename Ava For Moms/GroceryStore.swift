import Foundation
import Supabase

// MARK: - Model

struct GroceryListItem: Identifiable {
    let id: UUID
    let listId: UUID
    var name: String
    var quantity: String?
    var category: String?
    var tag: String?
    var checked: Bool
    var addedBy: String
}

extension GroceryListItem: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, name, quantity, category, tag, checked
        case listId   = "list_id"
        case addedBy  = "added_by"
    }
}

// MARK: - Store

@Observable
final class GroceryStore {

    var items: [GroceryListItem] = []
    var activeListId: UUID?
    var isLoading = false

    var unchecked: [GroceryListItem] { items.filter { !$0.checked } }
    var checked:   [GroceryListItem] { items.filter {  $0.checked } }

    // Items grouped by category for display
    var sections: [(title: String, items: [GroceryListItem])] {
        let categories = ["🥬 Produce", "🍖 Meat", "🧀 Dairy", "🍞 Pantry", "🧊 Frozen", "🛒 Other"]
        var result: [(String, [GroceryListItem])] = []
        for cat in categories {
            let key = cat.components(separatedBy: " ").dropFirst().joined(separator: " ").lowercased()
            let matching = items.filter { ($0.category ?? "other").lowercased() == key }
            if !matching.isEmpty { result.append((cat, matching)) }
        }
        // Items with no recognised category
        let known = Set(categories.map { $0.components(separatedBy: " ").dropFirst().joined(separator: " ").lowercased() })
        let other = items.filter { !known.contains(($0.category ?? "other").lowercased()) }
        if !other.isEmpty { result.append(("🛒 Other", other)) }
        return result
    }

    // MARK: - Load

    func load(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        struct ListRow: Decodable { let id: UUID }

        // Get or create active list
        let listId: UUID
        if let existing = activeListId {
            listId = existing
        } else if let rows = try? await supabase
            .from("grocery_lists")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .eq("archived", value: false)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value as [ListRow],
                  let first = rows.first {
            listId = first.id
            activeListId = first.id
        } else {
            // Create a new list
            let newId = UUID()
            _ = try? await (try? supabase.from("grocery_lists").insert([
                "id":       AnyJSON.string(newId.uuidString),
                "user_id":  AnyJSON.string(userId.uuidString),
                "archived": .bool(false),
            ] as [String: AnyJSON], returning: .minimal))?.execute()
            listId = newId
            activeListId = newId
        }

        if let loaded = try? await supabase
            .from("grocery_items")
            .select("id, list_id, name, quantity, category, tag, checked, added_by")
            .eq("list_id", value: listId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value as [GroceryListItem] {
            items = loaded
        }
    }

    // MARK: - Toggle

    func toggle(_ item: GroceryListItem) async {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].checked.toggle()
        let newValue = items[idx].checked

        let q = try? supabase.from("grocery_items")
            .update(["checked": AnyJSON.bool(newValue)], returning: .minimal)
            .eq("id", value: item.id.uuidString)
        _ = try? await q?.execute()
    }

    // MARK: - Add item

    func add(name: String, quantity: String? = nil, category: String? = nil, tag: String? = nil, userId: UUID) async {
        guard let listId = activeListId else { return }

        let newId = UUID()
        let newItem = GroceryListItem(id: newId, listId: listId, name: name,
                                      quantity: quantity, category: category,
                                      tag: tag, checked: false, addedBy: "user")
        items.append(newItem)

        var row: [String: AnyJSON] = [
            "id":       .string(newId.uuidString),
            "list_id":  .string(listId.uuidString),
            "user_id":  .string(userId.uuidString),
            "name":     .string(name),
            "checked":  .bool(false),
            "added_by": .string("user"),
        ]
        if let q = quantity, !q.isEmpty   { row["quantity"] = .string(q) }
        if let c = category, !c.isEmpty   { row["category"] = .string(c) }
        if let t = tag,      !t.isEmpty   { row["tag"]      = .string(t) }

        _ = try? await (try? supabase.from("grocery_items").insert(row, returning: .minimal))?.execute()
    }

    // MARK: - Remove item

    func remove(_ item: GroceryListItem) async {
        items.removeAll { $0.id == item.id }
        _ = try? await supabase.from("grocery_items").delete(returning: .minimal)
            .eq("id", value: item.id.uuidString).execute()
    }

    // MARK: - Clear all checked

    func clearChecked() async {
        let toRemove = items.filter { $0.checked }.map(\.id)
        items.removeAll { $0.checked }
        for id in toRemove {
            _ = try? await supabase.from("grocery_items").delete(returning: .minimal)
                .eq("id", value: id.uuidString).execute()
        }
    }
}
