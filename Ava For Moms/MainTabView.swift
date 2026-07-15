import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AvaTab = .home
    @State private var taskStore     = TaskStore()
    @State private var groceryStore  = GroceryStore()
    @State private var calendarStore = CalendarStore()
    @State private var notesStore    = NotesStore()
    @Environment(SubscriptionManager.self) private var store
    @Environment(AuthManager.self) private var auth

    private var isIPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environment(taskStore)
                .environment(groceryStore)
                .environment(calendarStore)
                .environment(notesStore)

            AvaTabBar(selected: $selectedTab)
                .padding(.bottom, isIPad ? 8 : 20)
        }
        // On iPad, respect safe areas so the ZStack + tab bar don't sit over
        // the home indicator zone (which blocks system-level touch handling).
        // Each content view's background already uses .ignoresSafeArea() so
        // the visual appearance is unchanged. iPhone keeps the original layout.
        .ignoresSafeArea(edges: isIPad ? [] : .all)
        // Load everything up front so Home has data on first launch —
        // previously only the Tasks/Calendar tabs loaded their own stores,
        // leaving the Today page empty until another tab was visited.
        .task(id: auth.currentUserId) {
            guard let userId = auth.currentUserId else { return }
            calendarStore.refreshAccessStatus()
            _Concurrency.Task { await taskStore.load(userId: userId) }
            _Concurrency.Task { await calendarStore.load(userId: userId, weekStart: Date().startOfWeek) }
            _Concurrency.Task { await groceryStore.load(userId: userId) }
            _Concurrency.Task { await notesStore.load(userId: userId) }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeView(onChatTap: { selectedTab = .chat })
        case .chat:
            ChatView(onBack: { selectedTab = .home })
        case .calendar:
            CalendarView(onChatTap: { selectedTab = .chat })
        case .tasks:
            TasksView(onChatTap: { selectedTab = .chat })
        case .grocery:
            GroceryView()
        }
    }
}

#Preview {
    MainTabView().environment(AuthManager())
}
