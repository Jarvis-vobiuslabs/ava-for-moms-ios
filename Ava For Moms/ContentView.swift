import SwiftUI

struct ContentView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        if hasOnboarded {
            MainTabView()
        } else {
            OnboardingView(onComplete: { hasOnboarded = true })
        }
    }
}

#Preview {
    ContentView()
}
