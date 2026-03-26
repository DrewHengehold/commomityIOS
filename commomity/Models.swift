import Foundation

// MARK: - Message / Inbox
struct InboxMessage: Identifiable {
    let id = UUID()
    let senderName: String
    let avatarImageName: String?
    let tag: MessageTag
    let preview: String
    let timestamp: String
    let isGroup: Bool
    let groupAvatars: [String]
}

enum MessageTag {
    case seekingHousing
    case seekingCareerAdvice
    case seekingWork
    case offeringHousing
    case offeringWork
    case none

    var label: String {
        switch self {
        case .seekingHousing:      return "Seeking Housing"
        case .seekingCareerAdvice: return "Seeking Career Advice"
        case .seekingWork:         return "Seeking Work"
        case .offeringHousing:     return "Offering Housing"
        case .offeringWork:        return "Offering Work"
        case .none:                return ""
        }
    }

    var isSeeking: Bool {
        switch self {
        case .seekingHousing, .seekingCareerAdvice, .seekingWork: return true
        default: return false
        }
    }
}

// MARK: - Community Post / Card
struct CommunityPost: Identifiable {
    let id = UUID()
    let personName: String
    let avatarImageName: String?
    let motherName: String
    let city: String
    let tag: PostTag
}

enum PostTag {
    case offeringHousing
    case seekingHousing
    case seekingCareerAdvice
    case seekingWork

    var label: String {
        switch self {
        case .offeringHousing:     return "Offering Housing"
        case .seekingHousing:      return "Seeking Housing"
        case .seekingCareerAdvice: return "Seeking Career Advice"
        case .seekingWork:         return "Seeking Work"
        }
    }

    var isSeeking: Bool {
        switch self {
        case .seekingHousing, .seekingCareerAdvice, .seekingWork: return true
        default: return false
        }
    }

    var cardColor: String {
        isSeeking ? "#F0D5B6" : "#C9E3E7"
    }
}

// MARK: - Connection
struct Connection: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let profession: String
    let city: String
    let avatarImageName: String?
}

// MARK: - Map Community
struct MapCommunity: Identifiable {
    let id = UUID()
    let name: String
    let memberCount: Int
    let members: [Connection]
}

// MARK: - Sample Data
struct SampleData {
    static let inboxMessages: [InboxMessage] = [
        InboxMessage(
            senderName: "Drew Hengehold",
            avatarImageName: nil,
            tag: .seekingHousing,
            preview: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor...",
            timestamp: "8:33 AM",
            isGroup: false,
            groupAvatars: []
        ),
        InboxMessage(
            senderName: "Drew & Ella",
            avatarImageName: nil,
            tag: .seekingCareerAdvice,
            preview: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor...",
            timestamp: "4/21/25",
            isGroup: true,
            groupAvatars: []
        ),
        InboxMessage(
            senderName: "Mac, Ella, Drew, Emma...",
            avatarImageName: nil,
            tag: .seekingWork,
            preview: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor...",
            timestamp: "15:33",
            isGroup: true,
            groupAvatars: []
        )
    ]

    static let communityPosts: [CommunityPost] = [
        CommunityPost(personName: "Drew", avatarImageName: nil, motherName: "Mother Rebecca Nagel", city: "San Francisco", tag: .offeringHousing),
        CommunityPost(personName: "Ella", avatarImageName: nil, motherName: "Mother Michelle Coddington", city: "San Francisco", tag: .seekingCareerAdvice),
        CommunityPost(personName: "Drew", avatarImageName: nil, motherName: "Mother Rebecca Nagel", city: "San Francisco", tag: .seekingHousing),
        CommunityPost(personName: "Drew", avatarImageName: nil, motherName: "Mother Rebecca Nagel", city: "San Francisco", tag: .seekingHousing),
        CommunityPost(personName: "Drew", avatarImageName: nil, motherName: "Mother Rebecca Nagel", city: "San Francisco", tag: .offeringHousing),
    ]

    static let connections: [Connection] = [
        Connection(name: "Rebecca Nagel", role: "Mother", profession: "Nursing", city: "San Francisco", avatarImageName: nil),
        Connection(name: "Drew Hengehold", role: "Son", profession: "Software Engineer", city: "San Francisco", avatarImageName: nil),
    ]

    static let mapCommunity = MapCommunity(
        name: "Petaluma Commomity",
        memberCount: 23,
        members: [
            Connection(name: "Drew Hengehold", role: "Son", profession: "Software Engineer", city: "San Francisco", avatarImageName: nil),
            Connection(name: "Drew Hengehold", role: "Son", profession: "Software Engineer", city: "San Francisco", avatarImageName: nil),
            Connection(name: "Drew Hengehold", role: "Son", profession: "Software Engineer", city: "San Francisco", avatarImageName: nil),
            Connection(name: "Drew Hengehold", role: "Son", profession: "Software Engineer", city: "San Francisco", avatarImageName: nil),
            Connection(name: "Drew Hengehold", role: "Son", profession: "Software Engineer", city: "San Francisco", avatarImageName: nil),
        ]
    )

    static let skillFields = [
        "Architecture", "Government",
        "Construction", "Medicine",
        "Tech", "Finance",
        "Teaching", "Artwork",
        "Business Management"
    ]
}
