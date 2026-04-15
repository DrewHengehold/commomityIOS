import Foundation
import Supabase

/// Centralised configuration. Credentials are loaded from Secrets.swift,
/// which is gitignored. Copy Secrets.swift.template → Secrets.swift to get started.
enum AppConfig {
    /// Shared Supabase client — used by both SupabaseService and AuthenticationService
    /// so they share the same auth session.
    static let supabase = SupabaseClient(
        supabaseURL: URL(string: Secrets.supabaseURL)!,
        supabaseKey: Secrets.supabaseAnonKey
    )
}
