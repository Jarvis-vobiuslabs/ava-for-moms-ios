import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AvaTab = .home
    @State private var taskStore     = TaskStore()
    @State private var groceryStore  = GroceryStore()
    @State private var calendarStore = CalendarStore()
    @State private var notesStore    = NotesStore()
    @Environment(SubscriptionManager.self) private var store

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
