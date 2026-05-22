import Foundation
import Supabase

// Handles all communication with the Ava chat edge function.
// Uses server-sent events (SSE) for streaming responses.

@Observable
final class ChatService {

    var messages: [ChatMessage] = []
    var isTyping = false
    var errorMessage: String?

    private var activeConversationId: UUID?

    // MARK: - Send a message to Ava

    func send(_ text: String, userId: UUID) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let conversationId = await ensureConversation(userId: userId)
        let userMsg = ChatMessage(role: .user, content: text)
        messages.append(userMsg)
        isTyping = true
        errorMessage = nil

        // Placeholder for Ava's reply — we stream into it
        var avaMsg = ChatMessage(role: .assistant, content: "")
        messages.append(avaMsg)
        let avaIndex = messages.count - 1

        do {
            let session = try await supabase.auth.session
            let token = session.accessToken

            var request = URLRequest(
                url: URL(string: "https://syhzfjrvbrqrsesxubtx.supabase.co/functions/v1/chat")!
            )
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN5aHpmanJ2YnJxcnNlc3h1YnR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwOTEwOTYsImV4cCI6MjA5MzY2NzA5Nn0.6vXXbQkc0R7GdO3F8lES6bqnoxC5rgaBzaYz3R8t1Dg",
                forHTTPHeaderField: "apikey"
            )
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "message": text,
                "conversationId": conversationId.uuidString,
            ])

            let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw ChatError.serverError
            }

            // Stream SSE lines
            for try await line in asyncBytes.lines {
                guard line.hasPrefix("data: ") else { continue }
                let payload = String(line.dropFirst(6))
                if payload == "[DONE]" { break }

                if let data = payload.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let chunk = json["text"] as? String {
                    avaMsg.content += chunk
                    messages[avaIndex] = avaMsg
                }
            }

            // Extract memories from this conversation in the background
            _Concurrency.Task {
                await extractMemories(conversationId: conversationId, token: token)
            }

        } catch {
            messages[avaIndex].content = "Something went wrong. Try again?"
            errorMessage = error.localizedDescription
        }

        isTyping = false
    }

    // MARK: - Ensure a conversation exists for today

    private func ensureConversation(userId: UUID) async -> UUID {
        if let existing = activeConversationId { return existing }

        // Try to get today's conversation
        let today = Calendar.current.startOfDay(for: Date())
        let result = try? await supabase
            .from("conversations")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .gte("created_at", value: ISO8601DateFormatter().string(from: today))
            .order("created_at", ascending: false)
            .limit(1)
            .execute()

        if let rows = try? result?.value as? [[String: Any]],
           let first = rows.first,
           let idStr = first["id"] as? String,
           let id = UUID(uuidString: idStr) {
            activeConversationId = id
            return id
        }

        // Create new conversation
        let newId = UUID()
        _ = try? await supabase.from("conversations").insert([
            "id": newId.uuidString,
            "user_id": userId.uuidString,
            "title": "Chat",
            "last_message_at": ISO8601DateFormatter().string(from: Date()),
        ]).execute()

        activeConversationId = newId
        return newId
    }

    // MARK: - Load history

    func loadHistory(userId: UUID) async {
        let conversationId = await ensureConversation(userId: userId)

        guard let result = try? await supabase
            .from("messages")
            .select("role, content")
            .eq("conversation_id", value: conversationId.uuidString)
            .order("created_at", ascending: true)
            .limit(50)
            .execute(),
              let rows = try? result.value as? [[String: Any]]
        else { return }

        messages = rows.compactMap { row in
            guard let roleStr = row["role"] as? String,
                  let content = row["content"] as? String,
                  let role = MessageRole(rawValue: roleStr)
            else { return nil }
            return ChatMessage(role: role, content: content)
        }
    }

    // MARK: - Extract memories (background, best-effort)

    private func extractMemories(conversationId: UUID, token: String) async {
        var request = URLRequest(
            url: URL(string: "https://syhzfjrvbrqrsesxubtx.supabase.co/functions/v1/extract-memory")!
        )
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN5aHpmanJ2YnJxcnNlc3h1YnR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwOTEwOTYsImV4cCI6MjA5MzY2NzA5Nn0.6vXXbQkc0R7GdO3F8lES6bqnoxC5rgaBzaYz3R8t1Dg",
            forHTTPHeaderField: "apikey"
        )
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "conversationId": conversationId.uuidString,
        ])
        _ = try? await URLSession.shared.data(for: request)
    }

    // MARK: - Types

    enum ChatError: Error { case serverError }
}

enum MessageRole: String { case user, assistant }

struct ChatMessage: Identifiable {
    let id = UUID()
    var role: MessageRole
    var content: String

    var isAva: Bool { role == .assistant }
}
