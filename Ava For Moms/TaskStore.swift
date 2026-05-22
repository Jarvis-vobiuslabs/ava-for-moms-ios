import Foundation
import Supabase

// MARK: - Model

struct AvaTask: Identifiable {
    let id: UUID
    var title: String
    var note: String?
    var priority: String   // "urgent" | "normal" | "low"
    var completed: Bool
}

extension AvaTask: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, title, note, priority, completed
    }
}

// MARK: - Store

@Observable
final class TaskStore {

    var urgent: [AvaTask] = []
    var normal: [AvaTask] = []
    var done:   [AvaTask] = []
    var isLoading = false

    var totalCount: Int { urgent.count + normal.count + done.count }
    var doneCount:  Int { done.count }

    // MARK: - Load

    func load(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        if let incomplete = try? await supabase
            .from("tasks")
            .select("id, title, note, priority, completed")
            .eq("user_id", value: userId.uuidString)
            .eq("completed", value: false)
            .order("created_at", ascending: true)
            .execute()
            .value as [AvaTask] {
            urgent = incomplete.filter { $0.priority == "urgent" }
            normal = incomplete.filter { $0.priority != "urgent" }
        }

        if let completed = try? await supabase
            .from("tasks")
            .select("id, title, note, priority, completed")
            .eq("user_id", value: userId.uuidString)
            .eq("completed", value: true)
            .order("created_at", ascending: false)
            .limit(15)
            .execute()
            .value as [AvaTask] {
            done = completed
        }
    }

    // MARK: - Complete / uncomplete

    func complete(_ task: AvaTask) async {
        urgent.removeAll { $0.id == task.id }
        normal.removeAll { $0.id == task.id }
        var t = task; t.completed = true
        done.insert(t, at: 0)

        let q = try? supabase.from("tasks")
            .update(["completed": AnyJSON.bool(true),
                     "completed_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))],
                    returning: .minimal)
            .eq("id", value: task.id.uuidString)
        _ = try? await q?.execute()
    }

    func uncomplete(_ task: AvaTask) async {
        done.removeAll { $0.id == task.id }
        var t = task; t.completed = false
        if t.priority == "urgent" { urgent.insert(t, at: 0) }
        else { normal.append(t) }

        let q = try? supabase.from("tasks")
            .update(["completed": AnyJSON.bool(false)], returning: .minimal)
            .eq("id", value: task.id.uuidString)
        _ = try? await q?.execute()
    }

    // MARK: - Add

    func add(title: String, note: String? = nil, priority: String = "normal", userId: UUID) async {
        let newId = UUID()
        let newTask = AvaTask(id: newId, title: title, note: note, priority: priority, completed: false)
        if priority == "urgent" { urgent.insert(newTask, at: 0) } else { normal.append(newTask) }

        var row: [String: AnyJSON] = [
            "id":        .string(newId.uuidString),
            "user_id":   .string(userId.uuidString),
            "title":     .string(title),
            "priority":  .string(priority),
            "completed": .bool(false),
            "source":    .string("user"),
        ]
        if let note, !note.trimmingCharacters(in: .whitespaces).isEmpty {
            row["note"] = .string(note)
        }

        _ = try? await (try? supabase.from("tasks").insert(row, returning: .minimal))?.execute()
    }

    // MARK: - Delete

    func delete(_ task: AvaTask) async {
        urgent.removeAll { $0.id == task.id }
        normal.removeAll { $0.id == task.id }
        done.removeAll   { $0.id == task.id }
        _ = try? await supabase.from("tasks").delete(returning: .minimal)
            .eq("id", value: task.id.uuidString).execute()
    }
}
