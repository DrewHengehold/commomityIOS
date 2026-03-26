import SwiftUI

struct ContentView: View {
    @State private var selectedTab: NavTab = .home
    @State private var isOnboarded: Bool = false  // set to true to skip onboarding

    var body: some View {
        if !isOnboarded {
            SignUpView()
        } else {
            mainApp
        }
    }

    private var mainApp: some View {
        ZStack(alignment: .bottom) {
            // Screen content
            Group {
                switch selectedTab {
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

            // Bottom nav bar
            BottomNavBar(selectedTab: $selectedTab)
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    ContentView()
}
