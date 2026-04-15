import Foundation
import FirebaseFirestore

// MARK: - User Role

enum UserRole: String, Codable, CaseIterable {
    case parent
    case child
}

// MARK: - Post Intent

/// Drives card + tag colours throughout the app.
/// seeking  → card: #F0D5B6  |  tag: #9D6402
/// offering → card: #C9E3E7  |  tag: #146974
enum PostIntent: String, Codable, CaseIterable {
    case seeking
    case offering

    var cardColorHex: String { self == .seeking ? "#F0D5B6" : "#C9E3E7" }
    var tagColorHex:  String { self == .seeking ? "#9D6402" : "#146974" }
    var label:        String { self == .seeking ? "Seeking"  : "Offering" }
}

// MARK: - Post Status

enum PostStatus: String, Codable, CaseIterable {
    case published
    case draft
    case fulfilled

    var displayLabel: String {
        switch self {
        case .published:  return "Published"
        case .draft:      return "Draft"
        case .fulfilled:  return "Fulfilled"
        }
    }

    var isVisible: Bool { self == .published }
}

// MARK: - Connection Status

enum ConnectionStatus: String, Codable {
    case pending
    case accepted
    case declined
    case blocked
}

// MARK: - Navigation Tab

/// Drives the bottom tab bar. Single source of truth shared across all views.
enum NavTab: Int, CaseIterable {
    case home, inbox, connections, map

    var iconName: String {
        switch self {
        case .home:        return "house.fill"
        case .inbox:       return "tray.fill"
        case .connections: return "person.2.fill"
        case .map:         return "map.fill"
        }
    }

    var label: String {
        switch self {
        case .home:        return "Home"
        case .inbox:       return "Inbox"
        case .connections: return "Connections"
        case .map:         return "Map"
        }
    }
}

// MARK: - User

/// Supabase-backed user record. Locations and skills are populated via
/// separate queries and not decoded from the users table directly.
struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    let role: String          // raw string so decoding never fails on unknown roles
    let fullName: String
    let avatarURL: String?
    let bio: String?

    var skills:    [String]       = []
    var locations: [UserLocation] = []

    enum CodingKeys: CodingKey {
        case id, email, role, fullName, avatarURL, bio
    }

    init(id: UUID, email: String, role: String, fullName: String,
         avatarURL: String? = nil, bio: String? = nil,
         skills: [String] = [], locations: [UserLocation] = []) {
        self.id = id; self.email = email; self.role = role
        self.fullName = fullName; self.avatarURL = avatarURL; self.bio = bio
        self.skills = skills; self.locations = locations
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(UUID.self,   forKey: .id)
        email     = try c.decode(String.self, forKey: .email)
        role      = try c.decode(String.self, forKey: .role)
        fullName  = try c.decode(String.self, forKey: .fullName)
        avatarURL = try c.decodeIfPresent(String.self, forKey: .avatarURL)
        bio       = try c.decodeIfPresent(String.self, forKey: .bio)
        skills    = []
        locations = []
    }
}

// MARK: - User Location

struct UserLocation: Codable, Equatable {
    let city:      String
    let isPrimary: Bool
    let addedAt:   Date
}

// MARK: - Community Post

/// Supabase-backed community post.
struct CommunityPost: Identifiable, Codable {
    let id:          UUID
    let authorId:    UUID
    let intent:      PostIntent
    let subject:     String
    let title:       String
    let description: String?
    let location:    String
    let status:      PostStatus
    let expiresAt:   Date?
    let createdAt:   Date

    /// Populated via a Supabase join — nil until resolved.
    var author: User?

    enum CodingKeys: CodingKey {
        case id, authorId, intent, subject, title, description,
             location, status, expiresAt, createdAt
    }

    init(id: UUID, authorId: UUID, intent: PostIntent, subject: String,
         title: String, description: String? = nil, location: String,
         status: PostStatus, expiresAt: Date? = nil, createdAt: Date,
         author: User? = nil) {
        self.id = id; self.authorId = authorId; self.intent = intent
        self.subject = subject; self.title = title; self.description = description
        self.location = location; self.status = status; self.expiresAt = expiresAt
        self.createdAt = createdAt; self.author = author
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self,       forKey: .id)
        authorId    = try c.decode(UUID.self,       forKey: .authorId)
        intent      = try c.decode(PostIntent.self, forKey: .intent)
        subject     = try c.decode(String.self,     forKey: .subject)
        title       = try c.decode(String.self,     forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        location    = try c.decode(String.self,     forKey: .location)
        status      = try c.decode(PostStatus.self, forKey: .status)
        expiresAt   = try c.decodeIfPresent(Date.self, forKey: .expiresAt)
        createdAt   = try c.decode(Date.self,       forKey: .createdAt)
        author      = nil
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,       forKey: .id)
        try c.encode(authorId, forKey: .authorId)
        try c.encode(intent,   forKey: .intent)
        try c.encode(subject,  forKey: .subject)
        try c.encode(title,    forKey: .title)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encode(location,  forKey: .location)
        try c.encode(status,    forKey: .status)
        try c.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try c.encode(createdAt, forKey: .createdAt)
    }
}

// MARK: - Connection Model

/// Supabase-backed connection request record.
struct ConnectionModel: Identifiable, Codable {
    let id:          UUID
    let requesterId: UUID
    let recipientId: UUID
    let status:      ConnectionStatus

    var requester: User?
    var recipient: User?
}

// MARK: - Display Connection

/// Lightweight UI snapshot of a user — used in MapView popups and ConnectionsView.
struct DisplayConnection: Identifiable {
    let id:              UUID
    let name:            String
    let role:            String
    let profession:      String
    let city:            String
    let avatarImageName: String?
}

// MARK: - Map Community

struct MapCommunity: Identifiable {
    let id:          UUID
    let name:        String
    let memberCount: Int
    let members:     [DisplayConnection]
}

// MARK: - Firestore Chat Models

/// A Firestore conversation document.
struct Conversation: Identifiable, Codable {
    @DocumentID var firestoreId: String?

    let participants:     [String]
    var participantNames: [String: String]?
    var lastMessage:      String
    var lastMessageAt:    Date
    let createdAt:        Date

    var id: String { firestoreId ?? UUID().uuidString }
    // displayName(currentUserId:) and toInboxMessage(currentUserId:) are
    // defined as an extension in InboxView.swift.
}

/// A single Firestore message inside a conversation.
struct Message: Identifiable, Codable {
    @DocumentID var firestoreId: String?

    let senderId:  String
    let text:      String
    let createdAt: Date
    var readBy:    [String]

    var id: String { firestoreId ?? UUID().uuidString }
}

// MARK: - Inbox Message (UI display model)

/// Flat display model for InboxView rows. Built from `Conversation` via
/// `Conversation.toInboxMessage(currentUserId:)`.
struct InboxMessage: Identifiable {
    let id:              UUID
    let conversationId:  String
    let senderName:      String
    let avatarImageName: String?
    let intent:          PostIntent?
    let subject:         String?
    let preview:         String
    let timestamp:       String
    let isGroup:         Bool
    let groupAvatars:    [String]
}

// MARK: - Sample Data

struct SampleData {

    // MARK: Inbox

    static let inboxMessages: [InboxMessage] = [
        InboxMessage(
            id: UUID(), conversationId: "sample-conv-1",
            senderName: "Drew Hengehold", avatarImageName: nil,
            intent: .seeking, subject: "Housing",
            preview: "Hey, I saw your post about the spare room — is it still available?",
            timestamp: "8:33 AM", isGroup: false, groupAvatars: []
        ),
        InboxMessage(
            id: UUID(), conversationId: "sample-conv-2",
            senderName: "Drew & Ella", avatarImageName: nil,
            intent: .seeking, subject: "Career Advice",
            preview: "We were hoping you could share some insights about breaking into the field.",
            timestamp: "4/21/25", isGroup: true, groupAvatars: []
        ),
        InboxMessage(
            id: UUID(), conversationId: "sample-conv-3",
            senderName: "Mac, Ella, Drew, Emma...", avatarImageName: nil,
            intent: nil, subject: nil,
            preview: "Welcome to the Petaluma Commomity group chat! Introduce yourself.",
            timestamp: "15:33", isGroup: true, groupAvatars: []
        )
    ]

    // MARK: Community Posts

    private static let authorA = UUID()
    private static let authorB = UUID()

    static let communityPosts: [CommunityPost] = [
        CommunityPost(
            id: UUID(), authorId: authorA, intent: .offering, subject: "Housing",
            title: "Private room available in 2BR apartment",
            description: "Quiet, furnished room near Caltrain. Utilities included. Month-to-month preferred.",
            location: "San Francisco", status: .published,
            expiresAt: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            createdAt: Date()
        ),
        CommunityPost(
            id: UUID(), authorId: authorB, intent: .seeking, subject: "Career Advice",
            title: "Looking for a mentor in product design",
            description: "Recent grad looking for someone with 5+ years of UX experience to meet monthly.",
            location: "San Francisco", status: .published,
            expiresAt: Calendar.current.date(byAdding: .day, value: 60, to: Date()),
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        ),
        CommunityPost(
            id: UUID(), authorId: authorA, intent: .seeking, subject: "Work",
            title: "Available for part-time contractor work",
            description: "Full-stack developer seeking 10–20 hours/week remote contracts. React, Swift, Node.",
            location: "Petaluma", status: .draft, expiresAt: nil,
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        ),
        CommunityPost(
            id: UUID(), authorId: authorB, intent: .offering, subject: "Artwork",
            title: "Free watercolor portraits for community members",
            description: "Practicing portraiture and happy to paint small portraits in exchange for a coffee.",
            location: "San Francisco", status: .published,
            expiresAt: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
            createdAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        ),
        CommunityPost(
            id: UUID(), authorId: authorA, intent: .seeking, subject: "Housing",
            title: "Need short-term housing for 6 weeks",
            description: "Between leases and looking for a room or studio for mid-May through late June.",
            location: "San Francisco", status: .fulfilled, expiresAt: nil,
            createdAt: Calendar.current.date(byAdding: .day, value: -21, to: Date()) ?? Date()
        )
    ]

    // MARK: Connections

    static let connections: [DisplayConnection] = [
        DisplayConnection(id: UUID(), name: "Rebecca Nagel",  role: "Mother", profession: "Nursing",           city: "San Francisco", avatarImageName: nil),
        DisplayConnection(id: UUID(), name: "Drew Hengehold", role: "Son",    profession: "Software Engineer", city: "San Francisco", avatarImageName: nil)
    ]

    // MARK: Map Community

    static let mapCommunity = MapCommunity(
        id: UUID(), name: "Petaluma Commomity", memberCount: 23,
        members: [
            DisplayConnection(id: UUID(), name: "Drew Hengehold",  role: "Son",      profession: "Software Engineer", city: "Petaluma", avatarImageName: nil),
            DisplayConnection(id: UUID(), name: "Rebecca Nagel",   role: "Mother",   profession: "Nursing",           city: "Petaluma", avatarImageName: nil),
            DisplayConnection(id: UUID(), name: "Ella Coddington", role: "Daughter", profession: "Graphic Designer",  city: "Petaluma", avatarImageName: nil),
            DisplayConnection(id: UUID(), name: "Mac Torres",       role: "Father",   profession: "Electrician",       city: "Petaluma", avatarImageName: nil),
            DisplayConnection(id: UUID(), name: "Emma Park",        role: "Daughter", profession: "Educator",          city: "Petaluma", avatarImageName: nil)
        ]
    )

    // MARK: Skill Fields

    static let skillFields: [String] = [
        "Architecture", "Government", "Construction", "Medicine",
        "Tech", "Finance", "Teaching", "Artwork", "Business Management"
    ]

    // MARK: Suggested Subjects

    static let suggestedSubjects: [String] = [
        "Housing", "Work", "Career Advice", "Artwork",
        "Free Equipment", "Tutoring", "Transportation",
        "Childcare", "Yard Work", "Small Jobs"
    ]

    // MARK: Fallback Cities (MapView)
    // These are shown even before anyone registers in a city, so users can
    // discover and join communities in smaller towns.

    static let fallbackCities: [String] = [
        "San Francisco", "Oakland", "Berkeley", "Petaluma", "San Jose",
        "Sonoma", "Napa", "Santa Rosa", "Marin", "Sausalito",
        "Mill Valley", "San Rafael", "Novato", "Fairfax", "Corte Madera",
        "Palo Alto", "Menlo Park", "Redwood City", "Burlingame",
        "Walnut Creek", "Concord", "Pleasant Hill", "Danville", "Livermore",
        "Fremont", "Hayward", "San Leandro", "Alameda", "Richmond",
        "Napa Valley", "Healdsburg", "Sebastopol", "Cotati", "Rohnert Park"
    ]
}
