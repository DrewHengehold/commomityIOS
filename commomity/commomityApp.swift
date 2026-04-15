import SwiftUI

@main
struct CommomityApp: App {
    @State private var router        = AppRouter()
    @State private var onboardingState = OnboardingState()
    @State private var session       = UserSessionManager()
    @State private var postStore     = PostStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
                .environment(onboardingState)
                .environment(session)
                .environment(postStore)
                .onOpenURL { url in
                    router.handle(url)
                }
                .task {
                    await session.restoreSession()
                }
        }
    }
}
