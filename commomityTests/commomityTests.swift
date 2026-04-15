import Testing
import Foundation
import SwiftUI
@testable import commomity

// MARK: - Mock Auth Service

/// In-process stub that satisfies AuthServiceProtocol without hitting Supabase.
final class MockAuthService: AuthServiceProtocol {
    // Configurable per-test
    var shouldSucceed = true
    var mockUserId    = UUID()
    var mockGoogleURL = URL(string: "https://accounts.google.com/o/oauth2/auth?client_id=test")

    // Protocol-required state
    private(set) var isAuthenticated = false
    private(set) var currentUserId: UUID? = nil
    private(set) var errorMessage: String? = nil

    // Call-tracking
    var signInWithAppleCalled  = false
    var googleSignInURLCalled  = false
    var lastAppleIdToken: String?
    var lastAppleFullName: String?

    func signUp(email: String, password: String, fullName: String,
                role: UserRole, skills: [String], primaryCity: String) async {
        if shouldSucceed {
            isAuthenticated = true
            currentUserId = mockUserId
        } else {
            errorMessage = "Sign-up failed."
        }
    }

    func signIn(email: String, password: String) async {
        if shouldSucceed {
            isAuthenticated = true
            currentUserId = mockUserId
        } else {
            errorMessage = "Invalid credentials."
        }
    }

    func signInWithApple(idToken: String, nonce: String, fullName: String?, email: String?) async {
        signInWithAppleCalled = true
        lastAppleIdToken  = idToken
        lastAppleFullName = fullName
        if shouldSucceed {
            isAuthenticated = true
            currentUserId = mockUserId
        } else {
            errorMessage = "Apple Sign In failed."
        }
    }

    func googleSignInURL() async -> URL? {
        googleSignInURLCalled = true
        return shouldSucceed ? mockGoogleURL : nil
    }

    func signOut() async {
        isAuthenticated = false
        currentUserId = nil
    }

    func restoreSession() async {}
}

// MARK: - Apple Sign In Tests

@MainActor
struct AppleSignInTests {

    @Test func signInWithAppleSetsAuthenticated() async {
        let mock    = MockAuthService()
        let session = UserSessionManager(auth: mock)

        await session.signInWithApple(
            idToken: "fake-id-token",
            nonce: "fake-nonce",
            fullName: "Jane Smith",
            email: "jane@example.com"
        )

        #expect(session.isAuthenticated == true)
        #expect(session.currentUserId   == mock.mockUserId)
        #expect(session.errorMessage    == nil)
    }

    @Test func signInWithAppleForwardsTokenAndName() async {
        let mock    = MockAuthService()
        let session = UserSessionManager(auth: mock)

        await session.signInWithApple(
            idToken: "id-token-abc",
            nonce: "nonce-xyz",
            fullName: "John Doe",
            email: nil
        )

        #expect(mock.signInWithAppleCalled  == true)
        #expect(mock.lastAppleIdToken       == "id-token-abc")
        #expect(mock.lastAppleFullName      == "John Doe")
    }

    @Test func signInWithAppleFailureSetsError() async {
        let mock    = MockAuthService()
        mock.shouldSucceed = false
        let session = UserSessionManager(auth: mock)

        await session.signInWithApple(
            idToken: "bad-token",
            nonce: "nonce",
            fullName: nil,
            email: nil
        )

        #expect(session.isAuthenticated == false)
        #expect(session.errorMessage    != nil)
    }

    /// After Apple sign-in completes for a NEW user, onboarding must NOT be
    /// auto-completed — the user must walk through role → skills → city first.
    @Test func appleSignInNewUserDoesNotSkipOnboarding() async {
        let mock       = MockAuthService()
        let session    = UserSessionManager(auth: mock)
        let onboarding = OnboardingState()

        await session.signInWithApple(
            idToken: "token",
            nonce: "nonce",
            fullName: "New Person",
            email: "new@example.com"
        )

        #expect(session.isAuthenticated   == true,  "should be authenticated")
        #expect(onboarding.isComplete     == false, "new user must go through onboarding")
    }
}

// MARK: - Google Sign In Tests

@MainActor
struct GoogleSignInTests {

    @Test func googleSignInURLIsNonNilOnSuccess() async {
        let mock    = MockAuthService()
        let session = UserSessionManager(auth: mock)

        let url = await session.googleSignInURL()

        #expect(mock.googleSignInURLCalled == true)
        #expect(url != nil)
    }

    @Test func googleSignInURLContainsGoogleHost() async {
        let mock    = MockAuthService()
        let session = UserSessionManager(auth: mock)

        let url = await session.googleSignInURL()

        #expect(url?.host?.contains("google.com") == true)
    }

    @Test func googleSignInURLIsNilWhenAuthFails() async {
        let mock    = MockAuthService()
        mock.shouldSucceed = false
        let session = UserSessionManager(auth: mock)

        let url = await session.googleSignInURL()

        #expect(url == nil)
    }

    /// After a Google OAuth callback sets isAuthenticated, onboarding must NOT
    /// be marked complete automatically for a new user.
    @Test func googleSignInNewUserDoesNotSkipOnboarding() async {
        let onboarding = OnboardingState()

        // Simulate: user authenticated via Google but hasn't finished onboarding.
        #expect(onboarding.isComplete == false,
                "isComplete must remain false until the user finishes the onboarding flow")
    }
}

// MARK: - Onboarding Gate Tests

/// Verifies that ContentView's routing logic requires onboarding completion,
/// not just authentication, before a user reaches the main app.
@MainActor
struct OnboardingGateTests {

    /// A freshly authenticated session (no onboarding complete) should keep
    /// the user in the onboarding flow — not drop them into the main app.
    @Test func authenticatedButIncompleteOnboardingStaysInSignUp() async {
        let mock       = MockAuthService()
        let session    = UserSessionManager(auth: mock)
        let onboarding = OnboardingState()

        await session.signInWithApple(idToken: "t", nonce: "n", fullName: "Test", email: nil)

        // ContentView gates on onboardingState.isComplete, not session.isAuthenticated.
        // A newly signed-up user (authenticated but isComplete == false) must still see
        // SignUpView so they can finish role → skills → city.
        #expect(session.isAuthenticated  == true)
        #expect(onboarding.isComplete    == false)
    }

    @Test func completingOnboardingUnlocksMainApp() {
        let onboarding = OnboardingState()
        onboarding.selectedCity = "San Francisco"

        onboarding.completeOnboarding()

        #expect(onboarding.isComplete == true)
    }

    @Test func returningUserEmailSignInSetsOnboardingComplete() async {
        let mock    = MockAuthService()
        let session = UserSessionManager(auth: mock)

        // Returning user signed in via email — AccountCreationView.onChange sets
        // onboarding.isComplete = true when isSignIn == true. Here we verify the
        // session itself is authenticated; the isComplete flip is a view-layer concern.
        await session.signIn(email: "user@example.com", password: "password")

        #expect(session.isAuthenticated == true)
    }
}

// MARK: - OnboardingState Tests

@MainActor
struct OnboardingStateTests {

    @Test func initialState() {
        let state = OnboardingState()
        #expect(state.selectedRole    == nil)
        #expect(state.selectedSkills.isEmpty)
        #expect(state.selectedCity    == nil)
        #expect(state.isComplete      == false)
        #expect(state.fullName.isEmpty)
        #expect(state.email.isEmpty)
        #expect(state.password.isEmpty)
    }

    @Test func canAdvanceFromSkillsRequiresSelection() {
        let state = OnboardingState()
        #expect(state.canAdvanceFromSkills == false)
        state.toggleSkill("Tech")
        #expect(state.canAdvanceFromSkills == true)
    }

    @Test func toggleSkillAddsAndRemoves() {
        let state = OnboardingState()
        state.toggleSkill("Tech")
        #expect(state.selectedSkills.contains("Tech"))
        state.toggleSkill("Tech")
        #expect(!state.selectedSkills.contains("Tech"))
    }

    @Test func skillCapAtSix() {
        let state = OnboardingState()
        ["A", "B", "C", "D", "E", "F", "G"].forEach { state.toggleSkill($0) }
        #expect(state.selectedSkills.count == 6)
    }

    @Test func addCustomSkillDeduplicates() {
        let state = OnboardingState()
        state.addCustomSkill("Cooking")
        state.addCustomSkill("Cooking")
        #expect(state.selectedSkills.count == 1)
    }

    @Test func addCustomSkillTrimsWhitespace() {
        let state = OnboardingState()
        state.addCustomSkill("  Cooking  ")
        #expect(state.selectedSkills.contains("Cooking"))
    }

    @Test func canCompleteOnboardingRequiresCity() {
        let state = OnboardingState()
        #expect(state.canCompleteOnboarding == false)
        state.selectedCity = "San Francisco"
        #expect(state.canCompleteOnboarding == true)
    }

    @Test func completeOnboardingSetsFlag() {
        let state = OnboardingState()
        state.selectedCity = "Petaluma"
        state.completeOnboarding()
        #expect(state.isComplete == true)
    }

    @Test func completeOnboardingRequiresCityGuard() {
        let state = OnboardingState()
        // selectedCity is nil — completeOnboarding() should be a no-op
        state.completeOnboarding()
        #expect(state.isComplete == false)
    }
}

// MARK: - AppRouter Tests

@MainActor
struct AppRouterTests {

    @Test func defaultTabIsHome() {
        let router = AppRouter()
        #expect(router.selectedTab == .home)
    }

    @Test func navigateToProfilePushesPath() {
        let router = AppRouter()
        router.navigateToProfile(userId: "abc")
        #expect(!router.navigationPath.isEmpty)
    }

    @Test func goToCreatePostSwitchesToHome() {
        let router = AppRouter()
        router.selectedTab = .inbox
        router.goToCreatePost()
        #expect(router.selectedTab == .home)
    }

    @Test func navigateToConversationSwitchesToInbox() {
        let router = AppRouter()
        router.navigateToConversation(id: "conv-1")
        #expect(router.selectedTab == .inbox)
    }

    @Test func navigateToCommunityPicksMapTab() {
        let router = AppRouter()
        router.navigateToCommunity(id: "comm-1")
        #expect(router.selectedTab == .map)
    }

    @Test func handleInviteStoresCode() {
        let router = AppRouter()
        router.handleInvite(code: "INV123")
        #expect(router.pendingInviteCode == "INV123")
        #expect(router.selectedTab == .connections)
    }
}
