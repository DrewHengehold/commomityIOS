import SwiftUI

struct InboxView: View {
    @Environment(UserSessionManager.self) private var session
    @State private var chatState = ChatState()
    @State private var selectedConversation: Conversation?

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Rectangle()
                    .fill(Color.black)
                    .frame(height: 1)
                    .padding(.top, 8)

                conversationList
            }
        }
        .onAppear {
            if let userId = session.currentUserId?.uuidString {
                chatState.subscribeToInbox(userId: userId)
            }
        }
        .onDisappear {
            chatState.unsubscribeInbox()
        }
        .fullScreenCover(item: $selectedConversation) { conversation in
            let currentId = session.currentUserId?.uuidString ?? ""
            let title = conversation.displayName(currentUserId: currentId)
            ChatView(
                conversationTitle: title,
                conversationId: conversation.id,
                isGroup: conversation.participants.count > 2,
                onDismiss: { selectedConversation = nil }
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            HamburgerIcon()
                .padding(.leading, 29)

            Spacer()

            Text("Inbox")
                .font(AppTheme.Fonts.playfair(36))
                .foregroundColor(.black)

            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#F7F7F7"))
                    .frame(width: 35, height: 35)
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black.opacity(0.85))
            }
            .padding(.trailing, 28)
        }
        .padding(.top, 14)
    }

    // MARK: - Conversation List

    @ViewBuilder
    private var conversationList: some View {
        if chatState.isLoadingConversations {
            Spacer()
            ProgressView()
            Spacer()
        } else if chatState.conversations.isEmpty {
            Spacer()
            Text("No messages yet")
                .font(AppTheme.Fonts.roboto(16))
                .foregroundColor(AppTheme.Colors.subtitleGray)
            Spacer()
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    let currentId = session.currentUserId?.uuidString ?? ""
                    ForEach(chatState.conversations) { conversation in
                        Button {
                            selectedConversation = conversation
                        } label: {
                            InboxRow(message: conversation.toInboxMessage(currentUserId: currentId))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Conversation → InboxMessage

extension Conversation {
    /// Display name shown in the inbox row. Lists the other participants' names.
    func displayName(currentUserId: String) -> String {
        let others = participants.filter { $0 != currentUserId }
        let names = others.compactMap { participantNames?[$0] }
        return names.isEmpty ? "Unknown" : names.joined(separator: ", ")
    }

    func toInboxMessage(currentUserId: String) -> InboxMessage {
        InboxMessage(
            id: UUID(),
            conversationId: firestoreId ?? "",
            senderName: displayName(currentUserId: currentUserId),
            avatarImageName: nil,
            intent: nil,
            subject: nil,
            preview: lastMessage.isEmpty ? "No messages yet" : lastMessage,
            timestamp: Self.formatTimestamp(lastMessageAt),
            isGroup: participants.count > 2,
            groupAvatars: []
        )
    }

    private static func formatTimestamp(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        } else if cal.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }
}

// MARK: - Inbox Row

struct InboxRow: View {
    let message: InboxMessage

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                avatarSection
                    .frame(width: 70)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(message.senderName)
                            .font(AppTheme.Fonts.roboto(18, weight: .bold))
                            .foregroundColor(.black)
                        Spacer()
                        Text(message.timestamp)
                            .font(AppTheme.Fonts.roboto(12, weight: .bold))
                            .foregroundColor(AppTheme.Colors.subtitleGray)
                    }

                    if let intent = message.intent, let subject = message.subject {
                        Text("\(intent.label) \(subject)")
                            .font(AppTheme.Fonts.roboto(15, weight: .bold))
                            .foregroundColor(Color(hex: intent.tagColorHex))
                    }

                    Text(message.preview)
                        .font(AppTheme.Fonts.roboto(12, weight: .light))
                        .foregroundColor(AppTheme.Colors.subtitleGray)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 12)

            Rectangle()
                .fill(Color(hex: "#BABABA"))
                .frame(height: 1)
                .padding(.leading, 59)
        }
    }

    @ViewBuilder
    private var avatarSection: some View {
        if message.isGroup {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.tileBackground)
                    .frame(width: 34, height: 34)
                    .offset(x: -8, y: -4)
                Circle()
                    .fill(AppTheme.Colors.tileBackground)
                    .frame(width: 30, height: 30)
                    .offset(x: 10, y: 4)
            }
            .frame(width: 60, height: 60)
        } else {
            AvatarCircle(size: 60)
        }
    }
}

// MARK: - Previews

#Preview("Inbox View") {
    let session = UserSessionManager()
    InboxView()
        .environment(session)
}

#Preview("Inbox Row - Single") {
    InboxRow(message: InboxMessage(
        id: UUID(), conversationId: "c1",
        senderName: "Drew Hengehold", avatarImageName: nil,
        intent: .seeking, subject: "Housing",
        preview: "Hey, I saw your post about the spare room — is it still available?",
        timestamp: "8:33 AM", isGroup: false, groupAvatars: []
    ))
    .padding()
}

#Preview("Inbox Row - Group") {
    InboxRow(message: InboxMessage(
        id: UUID(), conversationId: "c2",
        senderName: "Mac, Ella, Drew, Emma...", avatarImageName: nil,
        intent: .offering, subject: "Work",
        preview: "Welcome to the Petaluma Commomity group chat!",
        timestamp: "Yesterday", isGroup: true, groupAvatars: []
    ))
    .padding()
}

#Preview("Inbox Row - No Tag") {
    InboxRow(message: InboxMessage(
        id: UUID(), conversationId: "c3",
        senderName: "Sarah Johnson", avatarImageName: nil,
        intent: nil, subject: nil,
        preview: "Hey! Just wanted to check in and see how things are going.",
        timestamp: "2 days ago", isGroup: false, groupAvatars: []
    ))
    .padding()
}
