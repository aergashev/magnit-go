import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if app.isSignedIn {
                MainView()
                    .transition(.opacity)
            } else if !app.hasSeenWelcome {
                WelcomeView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: app.isSignedIn)
        .animation(.easeInOut(duration: 0.25), value: app.hasSeenWelcome)
    }
}
