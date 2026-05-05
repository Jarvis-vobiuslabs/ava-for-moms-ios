import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AvaTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            AvaTabBar(selected: $selectedTab)
                .padding(.bottom, 20)
        }
        .ignoresSafeArea()
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
    MainTabView()
}
