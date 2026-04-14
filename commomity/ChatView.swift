import SwiftUI

// MARK: - Chat View

struct ChatView: View {
    let conversationTitle: String
    let conversationId: String
    let isGroup: Bool
    var intent: PostIntent? = nil
    var subject: String? = nil
    var onDismiss: () -> Void

    @State private var chatState = ChatState()
    @Environment(UserSessionManager.self) private var session
    @FocusState private var inputFocused: Bool

    private var currentUserId: String {
        session.currentUserId?.uuidString ?? "me"
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .zIndex(1)

                Rectangle()
                    .fill(Color.black)
                    .frame(height: 1)

                messageList

                inputBar
            }
        }
        .onAppear {
            chatState.subscribeToMessages(conversationId: conversationId)
        }
        .onDisappear {
            chatState.unsubscribeMessages()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }
            .padding(.leading, 16)

            avatarIcon

            VStack(alignment: .leading, spacing: 1) {
                Text(conversationTitle)
                    .font(AppTheme.Fonts.roboto(17, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)

                if let intent, let subject {
                    Text("\(intent.label) \(subject)")
                        .font(AppTheme.Fonts.roboto(12, weight: .medium))
                        .foregroundColor(Color(hex: intent.tagColorHex))
                }
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .background(Color.white)
    }

    @ViewBuilder
    private var avatarIcon: some View {
        if isGroup {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.tileBackground)
                    .frame(width: 26, height: 26)
                    .offset(x: -6, y: -3)
                Circle()
                    .fill(AppTheme.Colors.tileBackground)
                    .frame(width: 22, height: 22)
                    .offset(x: 6, y: 3)
            }
            .frame(width: 42, height: 42)
        } else {
            AvatarCircle(size: 42)
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    if chatState.isLoadingMessages {
                        ProgressView()
                            .padding(.top, 40)
                    } else if chatState.activeMessages.isEmpty {
                        Text("No messages yet. Say hello!")
                            .font(AppTheme.Fonts.roboto(14))
                            .foregroundColor(AppTheme.Colors.subtitleGray)
                            .padding(.top, 40)
                    } else {
                        ForEach(chatState.activeMessages) { message in
                            MessageBubble(
                                message: message,
                                isFromMe: message.senderId == currentUserId
                            )
                            .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)
            }
            .onChange(of: chatState.activeMessages.count) { _, _ in
                if let last = chatState.activeMessages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                if let last = chatState.activeMessages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message...", text: $chatState.draftText, axis: .vertical)
                .font(AppTheme.Fonts.roboto(15))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "#F7F7F7"))
                )
                .lineLimit(1...5)
                .focused($inputFocused)

            Button {
                Task {
                    let text = chatState.draftText
                    chatState.draftText = ""
                    await chatState.sendMessage(
                        conversationId: conversationId,
                        text: text,
                        senderId: currentUserId
                    )
                }
                inputFocused = true
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(
                        chatState.draftText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color(hex: "#D0D0D0")
                            : AppTheme.Colors.childBlue
                    )
            }
            .disabled(chatState.draftText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(hex: "#BABABA"))
                .frame(height: 1)
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message
    let isFromMe: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromMe {
                Spacer(minLength: 64)
            } else {
                AvatarCircle(size: 28)
            }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 3) {
                Text(message.text)
                    .font(AppTheme.Fonts.roboto(15))
                    .foregroundColor(isFromMe ? .white : .black)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isFromMe ? AppTheme.Colors.childBlue : Color(hex: "#F0F0F0"))
                    )

                Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(AppTheme.Fonts.roboto(10))
                    .foregroundColor(AppTheme.Colors.subtitleGray)
            }

            if !isFromMe {
                Spacer(minLength: 64)
            }
        }
    }
}

// MARK: - Previews

#Preview("Chat View") {
    let session = UserSessionManager()
    ChatView(
        conversationTitle: "Drew Hengehold",
        conversationId: "preview-1",
        isGroup: false,
        intent: .seeking,
        subject: "Housing",
        onDismiss: {}
    )
    .environment(session)
}

#Preview("Chat View - Group") {
    let session = UserSessionManager()
    ChatView(
        conversationTitle: "Mac, Ella, Drew, Emma...",
        conversationId: "preview-2",
        isGroup: true,
        onDismiss: {}
    )
    .environment(session)
}
