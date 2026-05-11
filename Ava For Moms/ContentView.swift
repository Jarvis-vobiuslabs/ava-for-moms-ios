import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        switch auth.state {
        case .loading:
            splashView
        case .authenticated:
            MainTabView()
        case .unauthenticated:
            OnboardingFlowView()
        }
    }

    private var splashView: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()
            Circle()
                .fill(AvaTheme.blushTerracotta)
                .frame(width: 90, height: 90)
                .overlay(
                    Image(systemName: "face.smiling")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                )
        }
    }
}

#Preview {
    ContentView().environment(AuthManager())
}
