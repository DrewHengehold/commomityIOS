import SwiftUI

struct InboxView: View {
    let messages = SampleData.inboxMessages

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {

                // Header row
                HStack {
                    HamburgerIcon()
                        .padding(.leading, 29)

                    Spacer()

                    Text("Inbox")
                        .font(AppTheme.Fonts.playfair(36))
                        .foregroundColor(.black)

                    Spacer()

                    // Compose button
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

                // Divider
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 1)
                    .padding(.top, 8)

                // Message list
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                            InboxRow(message: message)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Inbox Row
struct InboxRow: View {
    let message: InboxMessage

    private var tagColor: Color {
        message.tag.isSeeking ? AppTheme.Colors.seekingTag : AppTheme.Colors.offeringTag
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Avatar(s)
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

                    if message.tag != .none {
                        Text(message.tag.label)
                            .font(AppTheme.Fonts.roboto(15, weight: .bold))
                            .foregroundColor(tagColor)
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

            // Separator
            Rectangle()
                .fill(Color(hex: "#BABABA"))
                .frame(height: 1)
                .padding(.leading, 59)
        }
    }

    @ViewBuilder
    private var avatarSection: some View {
        if message.isGroup {
            // Overlapping avatar cluster
            ZStack {
                // Back avatar
                Circle()
                    .fill(AppTheme.Colors.tileBackground)
                    .frame(width: 34, height: 34)
                    .offset(x: -8, y: -4)

                // Front avatar
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

extension MessageTag {
    static func != (lhs: MessageTag, rhs: MessageTag) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none): return false
        default: return true
        }
    }
}

// MARK: - Previews

#Preview("Inbox View") {
    InboxView()
}
#Preview("Inbox Row - Single User with Seeking Tag") {
    InboxRow(message: InboxMessage(
        senderName: "Drew Hengehold",
        avatarImageName: nil,
        tag: .seekingHousing,
        preview: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor...",
        timestamp: "8:33 AM",
        isGroup: false,
        groupAvatars: []
    ))
    .padding()
}

#Preview("Inbox Row - Group with Offering Tag") {
    InboxRow(message: InboxMessage(
        senderName: "Mac, Ella, Drew, Emma...",
        avatarImageName: nil,
        tag: .offeringWork,
        preview: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        timestamp: "Yesterday",
        isGroup: true,
        groupAvatars: []
    ))
    .padding()
}

#Preview("Inbox Row - No Tag") {
    InboxRow(message: InboxMessage(
        senderName: "Sarah Johnson",
        avatarImageName: nil,
        tag: .none,
        preview: "Hey! Just wanted to check in and see how things are going.",
        timestamp: "2 days ago",
        isGroup: false,
        groupAvatars: []
    ))
    .padding()
}

#Preview("Inbox Row - All Tag Types") {
    VStack(spacing: 0) {
        InboxRow(message: InboxMessage(
            senderName: "John Seeking Housing",
            avatarImageName: nil,
            tag: .seekingHousing,
            preview: "Looking for a place to stay in San Francisco.",
            timestamp: "Now",
            isGroup: false,
            groupAvatars: []
        ))
        
        InboxRow(message: InboxMessage(
            senderName: "Jane Offering Housing",
            avatarImageName: nil,
            tag: .offeringHousing,
            preview: "I have a spare room available starting next month.",
            timestamp: "5m ago",
            isGroup: false,
            groupAvatars: []
        ))
        
        InboxRow(message: InboxMessage(
            senderName: "Mike Career Advice",
            avatarImageName: nil,
            tag: .seekingCareerAdvice,
            preview: "Could really use some guidance on my career path.",
            timestamp: "1h ago",
            isGroup: false,
            groupAvatars: []
        ))
        
        InboxRow(message: InboxMessage(
            senderName: "Emily Work Group",
            avatarImageName: nil,
            tag: .seekingWork,
            preview: "Currently looking for opportunities in tech.",
            timestamp: "3h ago",
            isGroup: true,
            groupAvatars: []
        ))
        
        InboxRow(message: InboxMessage(
            senderName: "Tom Offering Work",
            avatarImageName: nil,
            tag: .offeringWork,
            preview: "We're hiring! Multiple positions available.",
            timestamp: "Yesterday",
            isGroup: false,
            groupAvatars: []
        ))
    }
}

#Preview("Inbox Row - Long Content Test") {
    InboxRow(message: InboxMessage(
        senderName: "Very Long Name That Should Be Truncated Eventually",
        avatarImageName: nil,
        tag: .seekingCareerAdvice,
        preview: "This is a very long preview message that should wrap to multiple lines and then be truncated after the second line. It contains a lot of text to test the layout behavior when messages are particularly verbose and detailed.",
        timestamp: "12:45 PM",
        isGroup: true,
        groupAvatars: []
    ))
    .padding()
}

#Preview("Inbox - Dark Mode") {
    InboxView()
        .preferredColorScheme(.dark)
}

#Preview("Inbox Row - Isolated for Testing") {
    ZStack {
        Color.white.ignoresSafeArea()
        VStack {
            InboxRow(message: SampleData.inboxMessages[0])
            Spacer()
        }
    }
}

