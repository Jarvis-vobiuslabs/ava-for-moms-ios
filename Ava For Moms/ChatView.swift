import SwiftUI

struct ChatView: View {
    let onBack: () -> Void
    @Environment(AuthManager.self) private var auth
    @Environment(CalendarStore.self) private var calendarStore
    @Environment(TaskStore.self) private var taskStore
    @Environment(GroceryStore.self) private var groceryStore
    @Environment(NotesStore.self) private var notesStore
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var chatService = ChatService()
    @State private var inputText = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var showNotes = false
    @State private var showFreeTrialPaywall = false
    @FocusState private var inputFocused: Bool

    private var isFreeTrialMode: Bool { UserDefaults.standard.bool(forKey: "ava.freeTrialMode") }
    private var freeMessageUsed: Bool { UserDefaults.standard.bool(forKey: "ava.freeMessageUsed") }
    private var isSubscribed: Bool { subscriptionManager.tier.isActive }

    // Bottom padding: sits above keyboard when open, above tab bar when closed
    private var composerBottomPad: CGFloat {
        keyboardHeight > 0 ? keyboardHeight + 8 : 112
    }

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                messageList
                composer
            }
        }
        // We track keyboard ourselves — prevent SwiftUI double-adjusting
        .ignoresSafeArea(.keyboard)
        .onReceive(NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillShowNotification)) { notif in
            guard let frame = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            withAnimation(.easeOut(duration: 0.28)) { keyboardHeight = frame.height }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.28)) { keyboardHeight = 0 }
        }
        .task {
            if let userId = auth.currentUserId {
                await chatService.loadHistory(userId: userId)
            }
        }
        .onChange(of: chatService.isTyping) { _, isTyping in
            guard !isTyping,
                  isFreeTrialMode,
                  !isSubscribed,
                  !freeMessageUsed,
                  chatService.messages.count >= 2 else { return }
            UserDefaults.standard.set(true, forKey: "ava.freeMessageUsed")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showFreeTrialPaywall = true
            }
        }
        .sheet(isPresented: $showFreeTrialPaywall) {
            PaywallView(data: OnboardingData(), onComplete: { showFreeTrialPaywall = false })
                .environment(auth)
                .environment(subscriptionManager)
        }
        .onChange(of: chatService.toolsExecuted) { _, tools in
            guard !tools.isEmpty, let userId = auth.currentUserId else { return }
            if tools.contains("add_calendar_event") {
                _Concurrency.Task { await calendarStore.load(userId: userId, weekStart: Date().startOfWeek) }
            }
            if tools.contains("add_task") {
                _Concurrency.Task { await taskStore.load(userId: userId) }
            }
            if tools.contains("add_grocery_item") {
                _Concurrency.Task { await groceryStore.load(userId: userId) }
            }
            if tools.contains("save_note") {
                _Concurrency.Task { await notesStore.load(userId: userId) }
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
            .contentShape(Rectangle())
            .buttonStyle(.plain)

            Circle().fill(AvaTheme.blushTerracotta).frame(width: 40, height: 40)
                .overlay(Image(systemName: "face.smiling")
                    .font(.system(size: 18, weight: .bold)).foregroundStyle(.white))
                .shadow(color: AvaTheme.terracotta.opacity(0.35), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Ava").font(AvaTheme.font(17, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                HStack(spacing: 4) {
                    Circle()
                        .fill(chatService.isTyping ? AvaTheme.terracotta : AvaTheme.sageDeep)
                        .frame(width: 6, height: 6)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                   value: chatService.isTyping)
                    Text(chatService.isTyping ? "typing…" : "your assistant")
                        .font(AvaTheme.font(11, weight: .bold))
                        .foregroundStyle(chatService.isTyping ? AvaTheme.terracotta : AvaTheme.sageDeep)
                }
            }
            Spacer()
            Button { showNotes = true } label: {
                Circle().fill(AvaTheme.cream).frame(width: 38, height: 38)
                    .overlay(Image(systemName: "note.text")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AvaTheme.inkMute))
            }
            .contentShape(Rectangle())
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18).padding(.top, 56).padding(.bottom, 14)
        .background(AvaTheme.bg)
        .sheet(isPresented: $showNotes) {
            NotesView().environment(auth).environment(notesStore)
        }
    }

    // MARK: - Messages

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    if chatService.messages.isEmpty && !chatService.isTyping {
                        emptyState
                    }
                    ForEach(chatService.messages) { msg in
                        LiveMessageBubble(message: msg).id(msg.id)
                    }
                    if chatService.isTyping && chatService.messages.last?.isAva == false {
                        typingIndicator
                    }
                    // Error banner
                    if let err = chatService.errorMessage {
                        Text(err)
                            .font(AvaTheme.font(13, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Capsule().fill(AvaTheme.terracotta.opacity(0.85)))
                            .padding(.horizontal, 18)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 20)
            }
            .onChange(of: chatService.messages.count) { _, _ in
                proxy.scrollTo("bottom", anchor: .bottom)
            }
            .onChange(of: chatService.messages.last?.content) { _, _ in
                proxy.scrollTo("bottom", anchor: .bottom)
            }
            .onChange(of: keyboardHeight) { _, h in
                if h > 0 { proxy.scrollTo("bottom", anchor: .bottom) }
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
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.15), value: chatService.isTyping)
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
        VStack(spacing: 8) {
            if freeTrialExhausted {
                Button { showFreeTrialPaywall = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill").font(.system(size: 12))
                        Text("Subscribe to keep chatting with Ava")
                            .font(AvaTheme.font(13, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Capsule().fill(AvaTheme.blushTerracotta))
                }
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
            }
            HStack(alignment: .bottom, spacing: 8) {
            TextField("Message Ava…", text: $inputText, axis: .vertical)
                .font(AvaTheme.font(15, weight: .medium))
                .foregroundStyle(AvaTheme.ink)
                .tint(AvaTheme.terracotta)
                .lineLimit(1...5)
                .padding(.leading, 16).padding(.vertical, 13)
                .focused($inputFocused)

            Button(action: sendMessage) {
                Circle()
                    .fill(canSend
                          ? AnyShapeStyle(AvaTheme.blushTerracotta)
                          : AnyShapeStyle(AvaTheme.line))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(canSend ? .white : AvaTheme.inkSoft)
                    )
                    .animation(.easeInOut(duration: 0.15), value: canSend)
            }
            .contentShape(Rectangle())
            .buttonStyle(.plain)
            .padding(.trailing, 6).padding(.bottom, 7)
            .disabled(!canSend)
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(AvaTheme.cream)
                .shadow(color: AvaTheme.ink.opacity(0.10), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AvaTheme.terracotta.opacity(inputFocused ? 0.4 : 0), lineWidth: 1.5)
        )
        .padding(.horizontal, 14)
        } // end VStack
        .padding(.bottom, composerBottomPad)
    }

    private var freeTrialExhausted: Bool { isFreeTrialMode && freeMessageUsed && !isSubscribed }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !chatService.isTyping
        && !freeTrialExhausted
    }

    // MARK: - Send

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !chatService.isTyping else { return }
        guard let userId = auth.currentUserId else {
            chatService.errorMessage = "Not signed in — please restart the app."
            return
        }
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
