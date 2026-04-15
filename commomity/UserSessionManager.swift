import Foundation
import Observation

@Observable
final class UserSessionManager {

    var currentUser: User? = nil
    var currentUserId: UUID? = nil
    var isAuthenticated: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private let auth: AuthServiceProtocol

    /// Default init uses the production Supabase auth service.
    /// Pass a mock to this initialiser in unit tests.
    init(auth: AuthServiceProtocol = AuthenticationService.shared) {
        self.auth = auth
    }

    // MARK: - Email Sign In / Sign Up

    func signIn(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        await auth.signIn(email: email, password: password)
        if auth.isAuthenticated {
            currentUserId = auth.currentUserId
            isAuthenticated = true
            await loadCurrentUser()
        } else {
            errorMessage = auth.errorMessage
        }
    }

    func signUp(
        email: String,
        password: String,
        fullName: String,
        onboardingState: OnboardingState
    ) async {
        isLoading = true
        defer { isLoading = false }
        guard let role = onboardingState.selectedRole,
              let city = onboardingState.selectedCity else {
            errorMessage = "Role and city are required."
            return
        }
        await auth.signUp(
            email: email,
            password: password,
            fullName: fullName,
            role: role,
            skills: Array(onboardingState.selectedSkills),
            primaryCity: city
        )
        if auth.isAuthenticated {
            currentUserId = auth.currentUserId
            isAuthenticated = true
            await loadCurrentUser()
        } else {
            errorMessage = auth.errorMessage
        }
    }

    // MARK: - Apple Sign In

    func signInWithApple(idToken: String, nonce: String, fullName: String?, email: String?) async {
        isLoading = true
        defer { isLoading = false }
        await auth.signInWithApple(idToken: idToken, nonce: nonce, fullName: fullName, email: email)
        if auth.isAuthenticated {
            currentUserId = auth.currentUserId
            isAuthenticated = true
            await loadCurrentUser()
        } else {
            errorMessage = auth.errorMessage
        }
    }

    // MARK: - Google Sign In (OAuth redirect)

    /// Returns the Supabase-generated Google OAuth URL to open in Safari.
    func googleSignInURL() async -> URL? {
        await auth.googleSignInURL()
    }

    // MARK: - Sign Out

    func signOut() {
        Task {
            await auth.signOut()
        }
        currentUser = nil
        currentUserId = nil
        isAuthenticated = false
    }

    // MARK: - Profile Loading

    func loadCurrentUser() async {
        guard let userId = auth.currentUserId else { return }
        do {
            currentUser = try await SupabaseService.shared.fetchUser(id: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Session Restoration

    func restoreSession() async {
        await auth.restoreSession()
        if auth.isAuthenticated {
            currentUserId = auth.currentUserId
            isAuthenticated = true
            await loadCurrentUser()
        }
    }
}
