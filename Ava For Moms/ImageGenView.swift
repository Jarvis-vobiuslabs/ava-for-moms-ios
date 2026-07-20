import SwiftUI
import Supabase

// Ava's Art Studio — Higgsfield image generation, 10/month on every plan.
// Failed/moderated generations are refunded server-side and the user is
// prompted to try again.

struct ImageGenView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var prompt = ""
    @State private var isGenerating = false
    @State private var resultImage: UIImage?
    @State private var remaining: Int?
    @State private var statusMessage: String?
    @State private var saved = false
    @FocusState private var promptFocused: Bool

    private let ideas: [(emoji: String, label: String, prompt: String)] = [
        ("🖍️", "Colouring page",
         "A black-and-white colouring page of a friendly unicorn, with the name Mia in big bubble letters at the top"),
        ("🎂", "Birthday card",
         "A cheerful birthday card cover with balloons and a golden retriever puppy, that says Happy Birthday Grandma"),
        ("🌙", "Bedtime art",
         "A cozy bedtime illustration of the moon reading a storybook to sleepy little stars"),
        ("🌻", "Cheer-up card",
         "A bright encouragement card with sunflowers that says You've got this, Mama!"),
    ]

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ─────────────────────────────────────────
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ava's Art Studio ✨")
                                .font(AvaTheme.font(24, weight: .heavy))
                                .foregroundStyle(AvaTheme.ink)
                                .tracking(-0.5)
                            if let remaining {
                                Text("\(remaining) of 10 creations left this month")
                                    .font(AvaTheme.font(12.5, weight: .semibold))
                                    .foregroundStyle(AvaTheme.inkMute)
                            }
                        }
                        Spacer()
                        Button { dismiss() } label: {
                            Circle().fill(AvaTheme.cream).frame(width: 36, height: 36)
                                .overlay(Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AvaTheme.inkMute))
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 26)
                    .padding(.bottom, 16)

                    // ── Result ─────────────────────────────────────────
                    if let img = resultImage {
                        VStack(spacing: 12) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .shadow(color: AvaTheme.ink.opacity(0.12), radius: 12, y: 6)

                            HStack(spacing: 10) {
                                Button {
                                    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                                    saved = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: saved ? "checkmark" : "square.and.arrow.down")
                                            .font(.system(size: 14, weight: .bold))
                                        Text(saved ? "Saved to Photos" : "Save to Photos")
                                            .font(AvaTheme.font(14, weight: .heavy))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Capsule().fill(saved ? AnyShapeStyle(AvaTheme.sageDeep) : AnyShapeStyle(AvaTheme.blushTerracotta)))
                                }
                                .contentShape(Rectangle())
                                .buttonStyle(.plain)

                                Button {
                                    resultImage = nil
                                    saved = false
                                    statusMessage = nil
                                } label: {
                                    Text("New image")
                                        .font(AvaTheme.font(14, weight: .bold))
                                        .foregroundStyle(AvaTheme.terracotta)
                                        .padding(.horizontal, 18).padding(.vertical, 14)
                                        .overlay(Capsule().stroke(AvaTheme.terracotta.opacity(0.5), lineWidth: 1.5))
                                }
                                .contentShape(Rectangle())
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.bottom, 24)
                    }

                    if resultImage == nil {
                        // ── Idea chips ─────────────────────────────────
                        Text("NEED AN IDEA?")
                            .font(AvaTheme.font(11, weight: .heavy))
                            .foregroundStyle(AvaTheme.inkSoft)
                            .tracking(0.8)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)

                        VStack(spacing: 8) {
                            ForEach(ideas, id: \.label) { idea in
                                Button {
                                    prompt = idea.prompt
                                    promptFocused = true
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(idea.emoji).font(.system(size: 20))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(idea.label)
                                                .font(AvaTheme.font(14, weight: .heavy))
                                                .foregroundStyle(AvaTheme.ink)
                                            Text(idea.prompt)
                                                .font(AvaTheme.font(12, weight: .medium))
                                                .foregroundStyle(AvaTheme.inkMute)
                                                .lineLimit(2)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.up.left")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(AvaTheme.inkSoft)
                                    }
                                    .padding(14)
                                    .background(RoundedRectangle(cornerRadius: 18).fill(AvaTheme.cream))
                                }
                                .contentShape(Rectangle())
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)

                        // ── Prompt ─────────────────────────────────────
                        VStack(spacing: 12) {
                            TextField("Describe the image you'd like…", text: $prompt, axis: .vertical)
                                .font(AvaTheme.font(15, weight: .medium))
                                .foregroundStyle(AvaTheme.ink)
                                .tint(AvaTheme.terracotta)
                                .lineLimit(3...6)
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 18).fill(AvaTheme.cream))
                                .focused($promptFocused)

                            Button(action: generate) {
                                ZStack {
                                    HStack(spacing: 8) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 15, weight: .bold))
                                        Text("Create it")
                                            .font(AvaTheme.font(16, weight: .heavy))
                                    }
                                    .opacity(isGenerating ? 0 : 1)
                                    if isGenerating {
                                        HStack(spacing: 10) {
                                            ProgressView().tint(.white)
                                            Text("Ava's drawing… about 30 seconds")
                                                .font(AvaTheme.font(14, weight: .bold))
                                        }
                                    }
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Capsule().fill(AvaTheme.blushTerracotta))
                                .opacity(canGenerate ? 1 : 0.5)
                            }
                            .contentShape(Rectangle())
                            .buttonStyle(.plain)
                            .disabled(!canGenerate)
                        }
                        .padding(.horizontal, 18)
                    }

                    if let msg = statusMessage {
                        Text(msg)
                            .font(AvaTheme.font(13.5, weight: .semibold))
                            .foregroundStyle(AvaTheme.terracottaDeep)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(AvaTheme.bgDeep))
                            .padding(.horizontal, 18)
                            .padding(.top, 14)
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
        .task { await loadRemaining() }
    }

    private var canGenerate: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !isGenerating
        && (remaining ?? 1) > 0
    }

    // MARK: - Generate

    private func generate() {
        promptFocused = false
        statusMessage = nil
        isGenerating = true
        _Concurrency.Task {
            defer { isGenerating = false }
            do {
                let session = try await supabase.auth.session
                var request = URLRequest(
                    url: URL(string: "https://syhzfjrvbrqrsesxubtx.supabase.co/functions/v1/generate-image")!
                )
                request.httpMethod = "POST"
                request.timeoutInterval = 150
                request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(
                    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN5aHpmanJ2YnJxcnNlc3h1YnR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwOTEwOTYsImV4cCI6MjA5MzY2NzA5Nn0.6vXXbQkc0R7GdO3F8lES6bqnoxC5rgaBzaYz3R8t1Dg",
                    forHTTPHeaderField: "apikey"
                )
                request.httpBody = try JSONSerialization.data(withJSONObject: [
                    "prompt": prompt.trimmingCharacters(in: .whitespacesAndNewlines),
                ])

                let (data, _) = try await URLSession.shared.data(for: request)
                struct GenResponse: Decodable {
                    let imagePath: String?
                    let remaining: Int?
                    let error: String?
                    let message: String?
                }
                let result = try JSONDecoder().decode(GenResponse.self, from: data)
                if let r = result.remaining { remaining = r }

                if let path = result.imagePath {
                    let url = try await supabase.storage.from("chat-images")
                        .createSignedURL(path: path, expiresIn: 3600)
                    let (imgData, _) = try await URLSession.shared.data(from: url)
                    if let img = UIImage(data: imgData) {
                        resultImage = img
                        saved = false
                    } else {
                        statusMessage = "Couldn't load the image — please try again"
                    }
                } else {
                    statusMessage = result.message ?? "Something went wrong — please try again"
                }
            } catch {
                statusMessage = "Something went wrong — please try again"
            }
        }
    }

    // MARK: - Remaining count

    private func loadRemaining() async {
        guard let userId = auth.currentUserId else { return }
        var comps = Calendar.current.dateComponents([.year, .month], from: Date())
        comps.day = 1
        let monthStart = Calendar.current.date(from: comps) ?? Date()
        let iso = ISO8601DateFormatter().string(from: monthStart)

        let count = try? await supabase.from("image_generations")
            .select("id", head: true, count: .exact)
            .eq("user_id", value: userId.uuidString)
            .neq("status", value: "refunded")
            .gte("created_at", value: iso)
            .execute()
            .count
        remaining = max(0, 10 - (count ?? 0))
    }
}

#Preview {
    ImageGenView().environment(AuthManager())
}
