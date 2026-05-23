import Foundation
import Supabase

struct AvaNote: Identifiable, Decodable {
    let id: UUID
    var title: String
    var content: String
    let source: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, content, source
        case createdAt = "created_at"
    }

    var isAva: Bool { source == "ava" }
}

@Observable
final class NotesStore {

    var notes: [AvaNote] = []
    var isLoading = false

    func load(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        if let loaded = try? await supabase
            .from("notes")
            .select("id, title, content, source, created_at")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value as [AvaNote] {
            notes = loaded
        }
    }

    func add(title: String, content: String, userId: UUID) async {
        let newId = UUID()
        let newNote = AvaNote(id: newId, title: title, content: content, source: "user", createdAt: Date())
        notes.insert(newNote, at: 0)

        _ = try? await (try? supabase.from("notes").insert([
            "id":      AnyJSON.string(newId.uuidString),
            "user_id": AnyJSON.string(userId.uuidString),
            "title":   AnyJSON.string(title),
            "content": AnyJSON.string(content),
            "source":  AnyJSON.string("user"),
        ] as [String: AnyJSON], returning: .minimal))?.execute()
    }

    func update(_ note: AvaNote) async {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx] = note
        }
        let q = try? supabase.from("notes")
            .update(["title": AnyJSON.string(note.title), "content": AnyJSON.string(note.content)], returning: .minimal)
            .eq("id", value: note.id.uuidString)
        _ = try? await q?.execute()
    }

    func delete(_ note: AvaNote) async {
        notes.removeAll { $0.id == note.id }
        _ = try? await supabase.from("notes").delete(returning: .minimal)
            .eq("id", value: note.id.uuidString).execute()
    }
}
