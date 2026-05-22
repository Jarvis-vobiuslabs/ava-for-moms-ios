import SwiftUI

struct ChatView: View {
    let onBack: () -> Void
    @Environment(AuthManager.self) private var auth
    @State private var chatService = ChatService()
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                messageList
                composer
            }
        }
        .task {
            if let userId = auth.currentUserId {
                await chatService.loadHistory(userId: userId)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Circle().fill(AvaTheme.cream).frame(width: 38, height: 38)
                    .overlay(Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AvaTheme.ink))
            }
            .buttonStyle(.plain)

            Circle().fill(AvaTheme.blushTerracotta).frame(width: 40, height: 40)
                .shadow(color: AvaTheme.terracotta.opacity(0.35), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Ava").font(AvaTheme.font(17, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                HStack(spacing: 4) {
                    Circle().fill(chatService.isTyping ? AvaTheme.terracotta : AvaTheme.sageDeep)
                        .frame(width: 6, height: 6)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: chatService.isTyping)
                    Text(chatService.isTyping ? "typing…" : "your assistant")
                        .font(AvaTheme.font(11, weight: .bold))
                        .foregroundStyle(chatService.isTyping ? AvaTheme.terracotta : AvaTheme.sageDeep)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 18).padding(.top, 56).padding(.bottom, 14)
    }

    // MARK: - Messages

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 10) {
                    if chatService.messages.isEmpty && !chatService.isTyping {
                        emptyState
                    }

                    ForEach(chatService.messages) { msg in
                        LiveMessageBubble(message: msg)
                            .id(msg.id)
                    }

                    if chatService.isTyping && chatService.messages.last?.isAva == false {
                        typingIndicator
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 20)
            }
            .onChange(of: chatService.messages.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom") }
            }
            .onChange(of: chatService.messages.last?.content) { _, _ in
                proxy.scrollTo("bottom")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Circle().fill(AvaTheme.blushTerracotta).frame(width: 64, height: 64)
                .overlay(Image(systemName: "face.smiling")
                    .font(.system(size: 28, weight: .bold)).foregroundStyle(.white))
                .padding(.top, 40)
            Text("Hey, I'm Ava 👋")
                .font(AvaTheme.font(20, weight: .heavy)).foregroundStyle(AvaTheme.ink)
            Text("I'm here to help with the mental load.\nWhat's on your mind?")
                .font(AvaTheme.font(15, weight: .medium)).foregroundStyle(AvaTheme.inkMute)
                .multilineTextAlignment(.center).lineSpacing(3)
        }
        .padding(.horizontal, 30)
    }

    private var typingIndicator: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(AvaTheme.inkSoft).frame(width: 7, height: 7)
                    .offset(y: chatService.isTyping ? -4 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                               value: chatService.isTyping)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(AvaTheme.cream)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 22, bottomLeadingRadius: 6,
            bottomTrailingRadius: 22, topTrailingRadius: 22))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Composer

    private var composer: some View {
        HStack(spacing: 8) {
            TextField("Message Ava…", text: $inputText, axis: .vertical)
                .font(AvaTheme.font(14.5, weight: .medium))
                .foregroundStyle(AvaTheme.ink)
                .lineLimit(1...5)
                .padding(.leading, 18).padding(.vertical, 14)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit { sendMessage() }

            Button(action: sendMessage) {
                Circle().fill(inputText.isEmpty ? AvaTheme.line : AnyShapeStyle(AvaTheme.blushTerracotta))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: inputText.isEmpty ? "mic.fill" : "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(inputText.isEmpty ? AvaTheme.inkSoft : .white))
                    .animation(.easeInOut(duration: 0.15), value: inputText.isEmpty)
                    .shadow(color: inputText.isEmpty ? .clear : AvaTheme.terracotta.opacity(0.4),
                            radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 6)
            .disabled(chatService.isTyping)
        }
        .background(AvaTheme.cream)
        .clipShape(Capsule())
        .shadow(color: AvaTheme.ink.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 14).padding(.bottom, 20)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !chatService.isTyping, let userId = auth.currentUserId else { return }
        inputText = ""
        _Concurrency.Task { await chatService.send(text, userId: userId) }
    }
}

// MARK: - Live message bubble

private struct LiveMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom) {
            if !message.isAva { Spacer(minLength: 60) }

            Text(message.content.isEmpty && message.isAva ? "…" : message.content)
                .font(AvaTheme.font(14.5, weight: .medium))
                .foregroundStyle(message.isAva ? AvaTheme.ink : .white)
                .lineSpacing(2)
                .padding(.horizontal, 16).padding(.vertical, 13)
                .background(message.isAva ? AvaTheme.cream : AvaTheme.terracotta)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 22,
                    bottomLeadingRadius: message.isAva ? 6 : 22,
                    bottomTrailingRadius: message.isAva ? 22 : 6,
                    topTrailingRadius: 22
                ))

            if message.isAva { Spacer(minLength: 60) }
        }
        .frame(maxWidth: .infinity, alignment: message.isAva ? .leading : .trailing)
    }
}

#Preview {
    ChatView(onBack: {}).environment(AuthManager())
}
