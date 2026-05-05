import SwiftUI

// MARK: - Chat data types (file-private so MessageBubble can reach them)

private enum ChatSender { case ava, user }

private struct ChatMessage: Identifiable {
    let id = UUID()
    let sender: ChatSender
    let text: String
    var showEventCard: Bool = false
    var showActions: Bool = false
}

private let sampleMessages: [ChatMessage] = [
    ChatMessage(sender: .ava,
                text: "Good morning, love ☀️ Theo's lunch is packed and by the door. How are you feeling?"),
    ChatMessage(sender: .user,
                text: "overwhelmed honestly. can we shuffle pilates?"),
    ChatMessage(sender: .ava,
                text: "On it. Sofía is open Thursday 9am — same time, different day. I'll hold your Tuesdays free for a bit. 💛",
                showEventCard: true, showActions: true),
]

// MARK: - ChatView

struct ChatView: View {
    let onBack: () -> Void
    @State private var messageText = ""

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                messageList
                composer
            }
        }
    }

    // ── Header ───────────────────────────────────────────────────────────

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Circle()
                    .fill(AvaTheme.cream)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AvaTheme.ink)
                    )
            }
            .buttonStyle(.plain)

            Circle()
                .fill(AvaTheme.blushTerracotta)
                .frame(width: 40, height: 40)
                .shadow(color: AvaTheme.terracotta.opacity(0.35), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Ava")
                    .font(AvaTheme.font(17, weight: .heavy))
                    .foregroundStyle(AvaTheme.ink)
                HStack(spacing: 4) {
                    Circle().fill(AvaTheme.sageDeep).frame(width: 6, height: 6)
                    Text("thinking with you")
                        .font(AvaTheme.font(11, weight: .bold))
                        .foregroundStyle(AvaTheme.sageDeep)
                }
            }

            Spacer()

            Circle()
                .fill(AvaTheme.cream)
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AvaTheme.ink)
                )
        }
        .padding(.horizontal, 18)
        .padding(.top, 56)
        .padding(.bottom, 14)
    }

    // ── Message list ─────────────────────────────────────────────────────

    private var messageList: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(sampleMessages) { msg in
                    MessageBubble(message: msg)
                }
                Text("Hold the mic to talk")
                    .font(AvaTheme.font(11, weight: .semibold))
                    .foregroundStyle(AvaTheme.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
        }
    }

    // ── Composer ─────────────────────────────────────────────────────────

    private var composer: some View {
        HStack(spacing: 8) {
            TextField("Message Ava…", text: $messageText)
                .font(AvaTheme.font(14.5, weight: .medium))
                .foregroundStyle(AvaTheme.ink)
                .padding(.leading, 18)
                .padding(.vertical, 14)

            Button(action: {}) {
                Circle()
                    .fill(AvaTheme.blushTerracotta)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: AvaTheme.terracotta.opacity(0.4), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 6)
        }
        .background(AvaTheme.cream)
        .clipShape(Capsule())
        .shadow(color: AvaTheme.ink.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 14)
        .padding(.bottom, 20)
    }
}

// MARK: - MessageBubble

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        let isAva = message.sender == .ava
        HStack(alignment: .bottom) {
            if !isAva { Spacer(minLength: 60) }
            VStack(alignment: isAva ? .leading : .trailing, spacing: 8) {
                Text(message.text)
                    .font(AvaTheme.font(14.5, weight: .medium))
                    .foregroundStyle(isAva ? AvaTheme.ink : .white)
                    .lineSpacing(2)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(isAva ? AvaTheme.cream : AvaTheme.terracotta)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 22,
                            bottomLeadingRadius: isAva ? 6 : 22,
                            bottomTrailingRadius: isAva ? 22 : 6,
                            topTrailingRadius: 22
                        )
                    )
                if message.showEventCard { eventCard }
                if message.showActions   { actionButtons }
            }
            if isAva { Spacer(minLength: 60) }
        }
        .frame(maxWidth: .infinity, alignment: isAva ? .leading : .trailing)
    }

    private var eventCard: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(AvaTheme.sage)
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("Pilates with Sofía")
                    .font(AvaTheme.font(14, weight: .heavy))
                    .foregroundStyle(AvaTheme.ink)
                Text("Thu, Apr 24 · 9:00 AM")
                    .font(AvaTheme.font(12, weight: .semibold))
                    .foregroundStyle(AvaTheme.inkMute)
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(AvaTheme.bg))
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button(action: {}) {
                Text("Confirm ✓")
                    .font(AvaTheme.font(13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(AvaTheme.terracotta)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Button(action: {}) {
                Text("Other time")
                    .font(AvaTheme.font(13, weight: .bold))
                    .foregroundStyle(AvaTheme.inkMute)
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .overlay(Capsule().stroke(AvaTheme.line, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    ChatView(onBack: {})
}
