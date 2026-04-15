import Foundation
import Observation
import SwiftUI

// MARK: - Typed Navigation Routes

enum Route: Hashable {
    case profile(String)           // userId
    case postDetail(String)        // postId
    case conversation(String)      // conversationId
    case communityDetail(String)   // communityId
    case createPost
    case myPosts
}

// MARK: - AppRouter

@Observable
final class AppRouter {
    var selectedTab: NavTab = .home
    var navigationPath = NavigationPath()

    /// Set when an /invite/{code} deep link arrives. Cleared after the invite is consumed.
    var pendingInviteCode: String? = nil

    // MARK: - Universal Link Handler

    /// Called from CommomityApp via `.onOpenURL`.
    func handle(_ url: URL) {
        guard let host = url.host,
              (host == "commomity.app" || host == "www.commomity.app") else { return }

        let parts = url.pathComponents.filter { $0 != "/" }
        guard !parts.isEmpty else { return }

        switch parts[0] {
        case "user"         where parts.count > 1: navigateToProfile(userId: parts[1])
        case "post"         where parts.count > 1: navigateToPost(postId: parts[1])
        case "conversation" where parts.count > 1: navigateToConversation(id: parts[1])
        case "community"    where parts.count > 1: navigateToCommunity(id: parts[1])
        case "invite"       where parts.count > 1: handleInvite(code: parts[1])
        default: break
        }
    }

    // MARK: - Navigation Helpers

    func navigateToProfile(userId: String) {
        navigationPath.append(Route.profile(userId))
    }

    func navigateToPost(postId: String) {
        selectedTab = .home
        navigationPath.append(Route.postDetail(postId))
    }

    func navigateToConversation(id: String) {
        selectedTab = .inbox
        navigationPath.append(Route.conversation(id))
    }

    func navigateToCommunity(id: String) {
        selectedTab = .map
        navigationPath.append(Route.communityDetail(id))
    }

    /// Stores the invite code for post-auth resolution and routes to the Connections tab.
    func handleInvite(code: String) {
        pendingInviteCode = code
        selectedTab = .connections
    }

    func goToCreatePost() {
        selectedTab = .home
        navigationPath.append(Route.createPost)
    }

    func goToMyPosts() {
        selectedTab = .home
        navigationPath.append(Route.myPosts)
    }
}
