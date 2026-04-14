import Foundation
import Observation
import FirebaseFirestore

// MARK: - Chat State

/// Observable state for both the inbox conversation list and an active chat thread.
/// One instance lives in InboxView (for the conversations list) and a separate
/// instance is created per ChatView (for its messages).
@Observable
final class ChatState {

    // MARK: Inbox (conversations list)
    var conversations: [Conversation] = []
    var isLoadingConversations = false

    // MARK: Active thread (messages)
    var activeMessages: [Message] = []
    var isLoadingMessages = false
    var draftText = ""

    // Listener handles — retained so they can be removed on teardown
    private var conversationListener: ListenerRegistration?
    private var messageListener: ListenerRegistration?

    // MARK: - Inbox

    /// Start a real-time listener that keeps `conversations` up to date.
    func subscribeToInbox(userId: String) {
        isLoadingConversations = true
        conversationListener?.remove()
        conversationListener = FirebaseService.shared.addConversationsListener(userId: userId) { [weak self] conversations in
            Task { @MainActor [weak self] in
                self?.conversations = conversations
                self?.isLoadingConversations = false
            }
        }
    }

    func unsubscribeInbox() {
        conversationListener?.remove()
        conversationListener = nil
        conversations = []
    }

    // MARK: - Active Thread

    /// Start a real-time listener that keeps `activeMessages` up to date.
    func subscribeToMessages(conversationId: String) {
        isLoadingMessages = true
        messageListener?.remove()
        messageListener = FirebaseService.shared.addMessagesListener(conversationId: conversationId) { [weak self] messages in
            Task { @MainActor [weak self] in
                self?.activeMessages = messages
                self?.isLoadingMessages = false
            }
        }
    }

    func unsubscribeMessages() {
        messageListener?.remove()
        messageListener = nil
        activeMessages = []
        draftText = ""
    }

    // MARK: - Send

    /// Send a message with an optimistic local append for instant feedback.
    func sendMessage(conversationId: String, text: String, senderId: String) async {
        let optimistic = Message(
            firestoreId: UUID().uuidString,
            senderId: senderId,
            text: text,
            createdAt: Date(),
            readBy: [senderId]
        )
        activeMessages.append(optimistic)

        do {
            try await FirebaseService.shared.sendMessage(
                conversationId: conversationId,
                text: text,
                senderId: senderId
            )
            // The snapshot listener will replace the optimistic message
            // with the server-confirmed version (including server timestamp).
        } catch {
            // Roll back the optimistic append
            activeMessages.removeAll { $0.id == optimistic.id }
            print("ChatState.sendMessage failed: \(error)")
        }
    }

    // MARK: - Create Conversation

    /// Create a new Firestore conversation and return its document ID.
    func createConversation(participants: [String], participantNames: [String: String]) async -> String? {
        do {
            return try await FirebaseService.shared.createConversation(
                participants: participants,
                participantNames: participantNames
            )
        } catch {
            print("ChatState.createConversation failed: \(error)")
            return nil
        }
    }

    /// Find an existing 1-to-1 conversation, or create one if none exists.
    func findOrCreateConversation(
        currentUserId: String,
        currentUserName: String,
        otherUserId: String,
        otherUserName: String
    ) async -> String? {
        do {
            if let existing = try await FirebaseService.shared.findConversation(
                between: currentUserId, and: otherUserId
            ) {
                return existing.id
            }
            return await createConversation(
                participants: [currentUserId, otherUserId],
                participantNames: [currentUserId: currentUserName, otherUserId: otherUserName]
            )
        } catch {
            print("ChatState.findOrCreateConversation failed: \(error)")
            return nil
        }
    }

    deinit {
        conversationListener?.remove()
        messageListener?.remove()
    }
}
