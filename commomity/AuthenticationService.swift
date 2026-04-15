import Foundation
import Observation
import Supabase

// MARK: - Protocol (enables mocking in unit tests)

protocol AuthServiceProtocol: AnyObject {
    var isAuthenticated: Bool { get }
    var currentUserId: UUID? { get }
    var errorMessage: String? { get }

    func signUp(email: String, password: String, fullName: String, role: UserRole, skills: [String], primaryCity: String) async
    func signIn(email: String, password: String) async
    func signInWithApple(idToken: String, nonce: String, fullName: String?, email: String?) async
    func googleSignInURL() async -> URL?
    func signOut() async
    func restoreSession() async
}

// MARK: - Production implementation

/// Wraps Supabase Auth for sign-up, sign-in, and session management.
/// Uses the shared AppConfig.supabase client so auth state is visible
/// to SupabaseService automatically.
@Observable
final class AuthenticationService: AuthServiceProtocol {

    static let shared = AuthenticationService()

    private(set) var isAuthenticated: Bool = false
    private(set) var currentUserId: UUID? = nil
    var isLoading: Bool = false
    private(set) var errorMessage: String? = nil

    private let client = AppConfig.supabase

    // MARK: - Sign Up

    /// Sign up with email/password, then persist the users row + locations + skills.
    func signUp(
        email: String,
        password: String,
        fullName: String,
        role: UserRole,
        skills: [String],
        primaryCity: String
    ) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await client.auth.signUp(email: email, password: password)
            guard let user = response.user else {
                errorMessage = "Sign-up failed — no user returned."
                return
            }
            let userId = UUID(uuidString: user.id.uuidString) ?? UUID()
            try await SupabaseService.shared.createUser(
                id: userId, email: email, role: role, fullName: fullName
            )
            try await SupabaseService.shared.addUserLocation(
                userId: userId, city: primaryCity, isPrimary: true
            )
            if !skills.isEmpty {
                try await SupabaseService.shared.addUserSkills(userId: userId, skillNames: skills)
            }
            currentUserId = userId
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Email Sign In

    func signIn(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            currentUserId = UUID(uuidString: session.user.id.uuidString)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Apple Sign In

    /// Exchange an Apple identity token for a Supabase session.
    /// `fullName` and `email` are only provided by Apple on the very first sign-in;
    /// they should be persisted to the users table at that point.
    func signInWithApple(idToken: String, nonce: String, fullName: String?, email: String?) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
            let userId = UUID(uuidString: session.user.id.uuidString) ?? UUID()
            currentUserId = userId
            isAuthenticated = true
            // Persist name + email on first sign-in when Apple provides them.
            if let name = fullName, !name.isEmpty {
                try? await SupabaseService.shared.updateUserName(userId: userId, fullName: name)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Google Sign In (OAuth redirect)

    /// Returns the Supabase-generated Google OAuth URL.
    /// The app opens this URL in Safari; the callback is handled via the
    /// `commomity://auth/callback` universal link in AppRouter.
    func googleSignInURL() async -> URL? {
        do {
            return try await client.auth.getOAuthSignInURL(
                provider: .google,
                redirectTo: URL(string: "commomity://auth/callback")
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
        isAuthenticated = false
        currentUserId = nil
    }

    // MARK: - Session Restoration

    /// Restores a saved Supabase session from the Keychain on app launch.
    func restoreSession() async {
        do {
            let session = try await client.auth.session
            currentUserId = UUID(uuidString: session.user.id.uuidString)
            isAuthenticated = true
        } catch {
            // No saved session — user needs to sign in.
            isAuthenticated = false
        }
    }
}
