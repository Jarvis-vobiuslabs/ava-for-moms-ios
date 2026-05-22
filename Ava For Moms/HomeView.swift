import SwiftUI

struct HomeView: View {
    let onChatTap: () -> Void
    @Environment(AuthManager.self) private var auth
    @Environment(TaskStore.self) private var taskStore
    @State private var showAccount = false
    @State private var avaSuggestionDismissed = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var todayString: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private var userInitial: String {
        String(auth.firstName.prefix(1)).uppercased()
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AvaTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ──────────────────────────────────────────
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Hey \(auth.firstName) 👋")
                                .font(AvaTheme.font(30, weight: .heavy))
                                .foregroundStyle(AvaTheme.ink)
                                .tracking(-0.8)
                            Text(todayString)
                                .font(AvaTheme.font(14, weight: .medium))
                                .foregroundStyle(AvaTheme.inkMute)
                        }
                        Spacer()
                        Button { showAccount = true } label: {
                            Circle()
                                .fill(AvaTheme.blushSage)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(userInitial)
                                        .font(AvaTheme.font(15, weight: .heavy))
                                        .foregroundStyle(.white)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 60)
                    .padding(.bottom, 16)

                    // ── Ava's Take card (dynamic) ────────────────────────
                    if !avaSuggestionDismissed {
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(.white.opacity(0.12))
                            .frame(width: 140, height: 140)
                            .offset(x: 20, y: -30)
                        Circle()
                            .fill(.white.opacity(0.08))
                            .frame(width: 90, height: 90)
                            .offset(x: -10, y: 70)

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle().fill(.white.opacity(0.25)).frame(width: 24, height: 24)
                                    Circle().fill(.white).frame(width: 10, height: 10)
                                }
                                Text("AVA'S TAKE")
                                    .font(AvaTheme.font(12, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .tracking(0.3)
                            }
                            Text(avaTakeMessage)
                                .font(AvaTheme.font(17, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineSpacing(3)
                            HStack(spacing: 8) {
                                Button(action: onChatTap) {
                                    Text("Yes please")
                                        .font(AvaTheme.font(13, weight: .bold))
                                        .foregroundStyle(AvaTheme.terracottaDeep)
                                        .padding(.horizontal, 16).padding(.vertical, 9)
                                        .background(.white)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                Button { avaSuggestionDismissed = true } label: {
                                    Text("Later")
                                        .font(AvaTheme.font(13, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16).padding(.vertical, 9)
                                        .overlay(Capsule().stroke(.white.opacity(0.6), lineWidth: 1.5))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(22)
                    }
                    .background(AvaTheme.blushTerracotta)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .padding(.horizontal, 18)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    } // end if !avaSuggestionDismissed

                    // ── Quick tiles ──────────────────────────────────────
                    let totalTasks = taskStore.urgent.count + taskStore.normal.count + taskStore.done.count
                    HStack(spacing: 10) {
                        quickTile(
                            color: AvaTheme.sage,
                            symbol: "checkmark",
                            label: "TASKS",
                            bigText: "\(taskStore.done.count)",
                            subText: totalTasks > 0 ? " / \(totalTasks)" : "",
                            caption: totalTasks == 0 ? "no tasks yet" : "checked off"
                        )
                        nextUpTaskTile
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)

                    // ── Today's tasks ────────────────────────────────────
                    let allIncomplete = taskStore.urgent + taskStore.normal
                    if !allIncomplete.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("Today's focus")
                                    .font(AvaTheme.font(17, weight: .heavy))
                                    .foregroundStyle(AvaTheme.ink)
                                Spacer()
                                Text("\(allIncomplete.count) task\(allIncomplete.count == 1 ? "" : "s")")
                                    .font(AvaTheme.font(12, weight: .bold))
                                    .foregroundStyle(AvaTheme.terracotta)
                            }
                            .padding(.bottom, 12)

                            ForEach(Array(allIncomplete.prefix(5))) { task in
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(task.priority == "urgent" ? AvaTheme.terracotta : AvaTheme.sage)
                                        .frame(width: 4, height: 30)
                                    Text(task.title)
                                        .font(AvaTheme.font(14.5, weight: .semibold))
                                        .foregroundStyle(AvaTheme.ink)
                                        .lineLimit(1)
                                    Spacer()
                                    if task.priority == "urgent" {
                                        Text("urgent")
                                            .font(AvaTheme.font(10, weight: .bold))
                                            .foregroundStyle(AvaTheme.terracotta)
                                    }
                                }
                                .padding(.vertical, 10)
                            }

                            if allIncomplete.count > 5 {
                                Text("+ \(allIncomplete.count - 5) more")
                                    .font(AvaTheme.font(12, weight: .medium))
                                    .foregroundStyle(AvaTheme.inkSoft)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 22)
                    } else if totalTasks > 0 {
                        // All done
                        HStack(spacing: 10) {
                            Text("🎉").font(.system(size: 22))
                            Text("All done for today!")
                                .font(AvaTheme.font(15, weight: .heavy))
                                .foregroundStyle(AvaTheme.ink)
                        }
                        .padding(.horizontal, 22).padding(.top, 22)
                    }

                    Spacer().frame(height: 130)
                }
            }

            // ── Ava FAB ────────────────────────────────────────────────
            Button(action: onChatTap) {
                Circle()
                    .fill(AvaTheme.blushTerracotta)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "face.smiling")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: AvaTheme.terracotta.opacity(0.4), radius: 12, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 18)
            .padding(.bottom, 100)
        }
        .sheet(isPresented: $showAccount) {
            AccountView().environment(auth)
        }
        .animation(.easeInOut(duration: 0.25), value: avaSuggestionDismissed)
    }

    // ── Sub-views ────────────────────────────────────────────────────────

    private func quickTile(color: Color, symbol: String, label: String,
                           bigText: String, subText: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle().fill(color).frame(width: 28, height: 28)
                    .overlay(Image(systemName: symbol)
                        .font(.system(size: 12, weight: .bold)).foregroundStyle(.white))
                Text(label)
                    .font(AvaTheme.font(11, weight: .bold))
                    .foregroundStyle(AvaTheme.inkMute)
                    .tracking(0.2)
            }
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(bigText).font(AvaTheme.font(26, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                Text(subText).font(AvaTheme.font(15, weight: .semibold)).foregroundStyle(AvaTheme.inkSoft)
            }
            Text(caption).font(AvaTheme.font(11.5, weight: .semibold)).foregroundStyle(AvaTheme.inkMute)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22).fill(AvaTheme.cream))
    }

    // Next urgent task tile (or a prompt to add one)
    private var nextUpTaskTile: some View {
        let next = taskStore.urgent.first ?? taskStore.normal.first
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle().fill(next != nil ? AvaTheme.terracotta : AvaTheme.blush).frame(width: 28, height: 28)
                    .overlay(Image(systemName: next?.priority == "urgent" ? "exclamationmark" : "checkmark.square")
                        .font(.system(size: 12, weight: .bold)).foregroundStyle(.white))
                Text("NEXT UP").font(AvaTheme.font(11, weight: .bold)).foregroundStyle(AvaTheme.inkMute).tracking(0.2)
            }
            if let task = next {
                Text(task.title).font(AvaTheme.font(16, weight: .heavy)).foregroundStyle(AvaTheme.ink).lineLimit(2)
                Text(task.priority == "urgent" ? "urgent 🔴" : "on your list")
                    .font(AvaTheme.font(11.5, weight: .semibold)).foregroundStyle(AvaTheme.inkMute)
            } else {
                Text("All clear!").font(AvaTheme.font(16, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                Text("Nothing pending").font(AvaTheme.font(11.5, weight: .semibold)).foregroundStyle(AvaTheme.inkMute)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22).fill(AvaTheme.cream))
    }

    // Dynamic Ava's Take — no API call, computed from real state
    private var avaTakeMessage: String {
        let urgentCount = taskStore.urgent.count
        let totalCount = taskStore.urgent.count + taskStore.normal.count
        let hour = Calendar.current.component(.hour, from: Date())

        if urgentCount > 0 {
            return "You've got \(urgentCount) urgent \(urgentCount == 1 ? "thing" : "things") on your list today. Want me to help you tackle them?"
        } else if totalCount > 3 {
            return "You have \(totalCount) things on your list. I can help you figure out what to handle first."
        } else if totalCount > 0 {
            return "Looks like a manageable day — \(totalCount) \(totalCount == 1 ? "task" : "tasks") on your list. You've got this 💛"
        } else if hour < 10 {
            return "Good morning! Your list is clear. Want me to help you plan today?"
        } else {
            return "Your list is empty. Tell me what's on your mind and I'll help you get it done."
        }
    }
}

#Preview {
    HomeView(onChatTap: {})
}
