import SwiftUI

struct ContentView: View {
    @Environment(OnboardingState.self) private var onboardingState
    @Environment(AppRouter.self) private var router
    @Environment(UserSessionManager.self) private var session
    @Environment(PostStore.self) private var postStore

    var body: some View {
        @Bindable var router = router
        Group {
            if onboardingState.isComplete || session.isAuthenticated {
                NavigationStack(path: $router.navigationPath) {
                    mainApp
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationDestination(for: Route.self) { route in
                            destination(for: route)
                        }
                }
            } else {
                SignUpView()
            }
        }
    }

    // MARK: - Route destinations

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .postDetail(let postId):
            if let uuid = UUID(uuidString: postId), let post = postStore.post(byId: uuid) {
                PostDetailView(post: post)
            } else {
                ContentUnavailableView("Post Not Found", systemImage: "doc.questionmark")
            }
        case .conversation(let id):
            Text("Conversation \(id)").navigationTitle("Conversation")
        case .profile(let userId):
            Text("Profile \(userId)").navigationTitle("Profile")
        case .communityDetail(let id):
            Text("Community \(id)").navigationTitle("Community")
        case .createPost:
            Text("Create Post").navigationTitle("Create Post")
        case .myPosts:
            Text("My Posts").navigationTitle("My Posts")
        }
    }

    // MARK: - Main app shell

    private var mainApp: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch router.selectedTab {
                    case .home:
                        CommunityView()
                    case .inbox:
                        InboxView()
                    case .connections:
                        ConnectionsView()
                    case .map:
                        MapView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                BottomNavBar(selectedTab: Binding(
                    get: { router.selectedTab },
                    set: { router.selectedTab = $0 }
                ))
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }
}

#Preview("Main App") {
    struct Preview: View {
        @State var onboardingState: OnboardingState = {
            let s = OnboardingState(); s.isComplete = true; return s
        }()
        @State var router = AppRouter()
        @State var session = UserSessionManager()
        @State var postStore = PostStore()
        var body: some View {
            ContentView()
                .environment(onboardingState)
                .environment(router)
                .environment(session)
                .environment(postStore)
        }
    }
    return Preview()
}

#Preview("Onboarding") {
    struct Preview: View {
        @State var onboardingState = OnboardingState()
        @State var router = AppRouter()
        @State var session = UserSessionManager()
        @State var postStore = PostStore()
        var body: some View {
            ContentView()
                .environment(onboardingState)
                .environment(router)
                .environment(session)
                .environment(postStore)
        }
    }
    return Preview()
}
