import Foundation
import Supabase
import UIKit

// Handles all communication with the Ava chat edge function.
// Uses server-sent events (SSE) for streaming responses.

@Observable
@MainActor
final class ChatService {

    var messages: [ChatMessage] = []
    var isTyping = false
    var errorMessage: String?
    var toolsExecuted: [String] = []   // populated after each message; triggers store refreshes

    private var activeConversationId: UUID?

    // MARK: - Send a message to Ava

    func send(_ text: String, image: UIImage? = nil, userId: UUID) async {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty || image != nil else { return }
        // The backend requires non-empty text; photos can go without a caption
        let outgoing = trimmed.isEmpty ? "Sent you a photo 📷" : trimmed

        let conversationId = await ensureConversation(userId: userId)

        // Upload the photo (downscaled) to the user's private folder first
        var imagePath: String? = nil
        if let image {
            let resized = image.resized(maxDimension: 1280)
            if let jpeg = resized.jpegData(compressionQuality: 0.7) {
                let path = "\(userId.uuidString.lowercased())/\(UUID().uuidString).jpg"
                do {
                    _ = try await supabase.storage.from("chat-images")
                        .upload(path, data: jpeg, options: FileOptions(contentType: "image/jpeg"))
                    imagePath = path
                } catch {
                    errorMessage = "Photo upload failed — sending without it"
                }
            }
        }

        let userMsg = ChatMessage(role: .user, content: outgoing, localImage: imagePath != nil ? image : nil, imagePath: imagePath)
        messages.append(userMsg)
        isTyping = true
        errorMessage = nil
        toolsExecuted = []

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
            let offsetMinutes = TimeZone.current.secondsFromGMT() / 60
            var payload: [String: Any] = [
                "message": outgoing,
                "conversationId": conversationId.uuidString,
                "timezone": TimeZone.current.identifier,
                "timezoneOffsetMinutes": offsetMinutes,
            ]
            if let imagePath { payload["imagePath"] = imagePath }
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard status == 200 else {
                var body = Data()
                for try await byte in asyncBytes { body.append(byte) }
                let detail = String(data: body, encoding: .utf8) ?? "no body"
                throw ChatError.httpError(status, detail)
            }

            // Stream SSE lines
            for try await line in asyncBytes.lines {
                guard line.hasPrefix("data: ") else { continue }
                let payload = String(line.dropFirst(6))
                if payload == "[DONE]" { break }

                if let data = payload.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let chunk = json["text"] as? String {
                        avaMsg.content += chunk
                        messages[avaIndex] = avaMsg
                    }
                    if let tools = json["tools"] as? [String] {
                        toolsExecuted = tools
                    }
                }
            }

            // Extract memories from this conversation in the background
            _Concurrency.Task {
                await extractMemories(conversationId: conversationId, token: token)
            }

        } catch let ChatError.httpError(code, detail) {
            messages[avaIndex].content = "Error \(code) — \(detail)"
            errorMessage = "HTTP \(code)"
        } catch {
            messages[avaIndex].content = "Something went wrong: \(error.localizedDescription)"
            errorMessage = error.localizedDescription
        }

        isTyping = false
    }

    // MARK: - Ensure a conversation exists for today

    private func ensureConversation(userId: UUID) async -> UUID {
        if let existing = activeConversationId { return existing }

        // Try to get today's conversation using typed decode
        struct ConvRow: Decodable { let id: UUID }
        let today = Calendar.current.startOfDay(for: Date())

        if let rows = try? await supabase
            .from("conversations")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .gte("created_at", value: ISO8601DateFormatter().string(from: today))
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value as [ConvRow],
           let first = rows.first {
            activeConversationId = first.id
            return first.id
        }

        // Create new conversation (double-try? matches Supabase Swift SDK throwing pattern)
        let newId = UUID()
        _ = try? await (try? supabase.from("conversations").insert([
            "id": AnyJSON.string(newId.uuidString),
            "user_id": AnyJSON.string(userId.uuidString),
            "title": AnyJSON.string("Chat"),
            "last_message_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date())),
        ] as [String: AnyJSON], returning: .minimal))?.execute()

        activeConversationId = newId
        return newId
    }

    // MARK: - Load history

    func loadHistory(userId: UUID) async {
        let conversationId = await ensureConversation(userId: userId)

        struct MsgRow: Decodable {
            let role: String
            let content: String
            let imagePath: String?
            enum CodingKeys: String, CodingKey {
                case role, content
                case imagePath = "image_path"
            }
        }

        guard let rows = try? await supabase
            .from("messages")
            .select("role, content, image_path")
            .eq("conversation_id", value: conversationId.uuidString)
            .order("created_at", ascending: true)
            .limit(50)
            .execute()
            .value as [MsgRow]
        else { return }

        messages = rows.compactMap { row in
            guard let role = MessageRole(rawValue: row.role) else { return nil }
            return ChatMessage(role: role, content: row.content, imagePath: row.imagePath)
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

    enum ChatError: Error { case serverError; case httpError(Int, String) }
}

enum MessageRole: String { case user, assistant }

struct ChatMessage: Identifiable {
    let id = UUID()
    var role: MessageRole
    var content: String
    var localImage: UIImage? = nil   // just-sent photo, shown immediately
    var imagePath: String? = nil     // storage path, for history reloads

    var isAva: Bool { role == .assistant }
}

extension UIImage {
    // Downscale for upload — keeps chat snappy and vision costs low
    func resized(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
