import Foundation
import Observation

// MARK: - PostStore

/// Observable store for community posts. Backed by SupabaseService in production;
/// the `preview` static instance uses SampleData for Xcode Previews.
@Observable
final class PostStore {

    // MARK: - State

    var posts: [CommunityPost] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: - Filtered Access

    /// Returns published posts filtered by intent, or all published posts if intent is nil.
    func posts(for intent: PostIntent?) -> [CommunityPost] {
        posts
            .filter { $0.status == .published }
            .filter { intent == nil || $0.intent == intent }
    }

    /// Looks up a post by its UUID. Used by ContentView to resolve postDetail navigation routes.
    func post(byId id: UUID) -> CommunityPost? {
        posts.first { $0.id == id }
    }

    // MARK: - Remote Fetch

    func fetchPublished(city: String = "") async {
        isLoading = true
        defer { isLoading = false }
        do {
            posts = try await SupabaseService.shared.fetchPublishedPosts(city: city)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Create

    func saveDraft(
        intent: PostIntent,
        subject: String,
        title: String,
        description: String,
        location: String,
        authorId: UUID
    ) async {
        do {
            let post = try await SupabaseService.shared.createPost(
                authorId: authorId,
                intent: intent,
                subject: subject,
                title: title,
                description: description.isEmpty ? nil : description,
                location: location,
                status: .draft,
                expiresAt: nil
            )
            posts.append(post)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func publish(
        intent: PostIntent,
        subject: String,
        title: String,
        description: String,
        location: String,
        authorId: UUID
    ) async {
        do {
            let post = try await SupabaseService.shared.createPost(
                authorId: authorId,
                intent: intent,
                subject: subject,
                title: title,
                description: description.isEmpty ? nil : description,
                location: location,
                status: .published,
                expiresAt: nil
            )
            posts.append(post)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Update Status

    func publishPost(id: UUID) async {
        do {
            try await SupabaseService.shared.updatePost(id: id, updates: PostUpdate(status: .published))
            if let idx = posts.firstIndex(where: { $0.id == id }) {
                let old = posts[idx]
                posts[idx] = CommunityPost(
                    id: old.id, authorId: old.authorId, intent: old.intent,
                    subject: old.subject, title: old.title, description: old.description,
                    location: old.location, status: .published,
                    expiresAt: old.expiresAt, createdAt: old.createdAt
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fulfillPost(id: UUID) async {
        do {
            try await SupabaseService.shared.fulfillPost(id: id)
            if let idx = posts.firstIndex(where: { $0.id == id }) {
                let old = posts[idx]
                posts[idx] = CommunityPost(
                    id: old.id, authorId: old.authorId, intent: old.intent,
                    subject: old.subject, title: old.title, description: old.description,
                    location: old.location, status: .fulfilled,
                    expiresAt: old.expiresAt, createdAt: old.createdAt
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Preview

    @MainActor
    static let preview: PostStore = {
        let store = PostStore()
        store.posts = SampleData.communityPosts
        return store
    }()
}
