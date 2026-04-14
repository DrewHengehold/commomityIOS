# Commomity App Guide
> iOS (SwiftUI) · iOS 17+ · Last Updated: April 7, 2026 · Implementation Phase: Phase 1 scaffolding complete

---

## Overview

**Commomity** is a parent networking app for connecting families within local communities. Core value: "An app built for the parent network" — connecting via shared needs, skills, and geographic proximity.

**Four main features:**
1. **Community Feed** — Marketplace-style listings as Seeking/Offering posts; subject matter is open-ended and grows over time
2. **Inbox** — Direct & group messaging tagged by post intent
3. **Connections** — Network of parents/children with role, profession, and cities
4. **Map** — MapKit geographic community discovery; users add locations here to join multiple communities

---

## Architecture

### Tech Stack

| Layer | Technology | Why |
|---|---|---|
| UI | SwiftUI (iOS 17+) | Declarative, live previews, native MapKit |
| State | `@Observable` (Observation framework) | Replaces `ObservableObject` — cleaner, more performant, no `@Published` needed |
| Database | Supabase (PostgreSQL + PostGIS) | Relational structure for users/posts/connections; geographic queries |
| Chat | Firebase Firestore | Real-time listeners exclusively for chat; keep free tier |
| Deep Links | Apple Universal Links | No third-party dependency; survives Firebase Dynamic Links shutdown |
| Local Cache | SwiftData (Phase 3) | Offline support, onboarding persistence |

### Key Design Decisions

1. **`@Observable` only** — use `@Bindable` for two-way bindings in views; no `ObservableObject`, `@StateObject`, or `@EnvironmentObject` anywhere
2. **Hybrid DB** — Supabase for all structured data, Firestore only for chat messages (no data duplication except user UUIDs)
3. **Sample data first** — all views use `SampleData`; service stubs are in place ready for SDK wiring
4. **Flat tab navigation** — `AppRouter` owns `selectedTab` and `navigationPath`; deep links call `AppRouter.handle()` which switches tabs and pushes typed `Route` values
5. **Single source of truth per domain** — `OnboardingState`, `UserSessionManager`, `AppRouter`, `ChatState` each own one domain
6. **Service layer is `actor` or `@Observable`** — `SupabaseService` and `FirebaseService` are Swift `actor` types for thread safety; `AuthenticationService` and `LocationService` are `@Observable` classes for UI binding
7. **`NavTab` lives in `Models.swift`** — single definition shared by all files; removed from `SharedComponents.swift`

---

## Project Structure

All Swift files are flat in a single directory (the Xcode project group structure is logical, not on disk). The intended future organization is shown in parentheses.

```
commomity/                          (all files at this level)
│
│  — App —
├── CommomityApp.swift              # @main entry, injects @Observable state + Universal Links
├── ContentView.swift               # Onboarding gate + tab container, reads from AppRouter
│
│  — Onboarding —
├── SignUpView.swift                # Contains RoleSelectionView, SkillSelectionView,
│                                   # LocationSelectionView as sub-views in one file
│
│  — Features —
├── CommunityView.swift             # Home feed + CommunityCard; intent-based filtering
├── CreatePostView.swift            # Post creation form (draft/publish) + MyPostsView
├── InboxView.swift                 # Message list + InboxRow
├── ConnectionsView.swift           # Connections list + ConnectionRow + ExtendCommunityCard
├── MapView.swift                   # MapKit view + CommunityPopup + AddCityConfirmationView
│
│  — State (@Observable, no SDKs needed) —
├── OnboardingState.swift           # Role, skills, city selection; completeOnboarding()
├── UserSessionManager.swift        # currentUser, isAuthenticated, sign-in/out stubs
├── AppRouter.swift                 # selectedTab, navigationPath, Universal Link handler
├── ChatState.swift                 # conversations, activeMessages, Firestore stubs
│
│  — Services (stubs, ready for SDK integration) —
├── SupabaseService.swift           # actor: all DB queries (users, posts, connections, locations)
├── AuthenticationService.swift     # @Observable: Supabase Auth sign-up/in/out stubs
├── FirebaseService.swift           # actor: Firestore chat stubs (messages, conversations)
├── LocationService.swift           # @Observable: CLLocationManager + reverse geocoding (real)
│
│  — Models —
├── Models.swift                    # All types: enums, structs, SampleData
│
│  — Design —
├── Theme.swift                     # AppTheme: colors, fonts, layout constants
├── SharedComponents.swift          # Reusable views: BottomNavBar, AvatarCircle, FilterPill, etc.
│
│  — Legacy / Unused —
└── Persistence.swift               # CoreData template — unused, safe to delete
```

### Notes on current file layout vs. intended structure
- The subdirectory layout (App/, Features/, State/, etc.) is the **intended Xcode group structure** for when the project is reorganized. Files are not yet in subdirectories on disk.
- `SignUpView.swift` contains all three onboarding steps as sub-views (not separate files).
- `CommunityPopup` and `AddCityConfirmationView` live inside `MapView.swift`.
- `MyPostsView` lives inside `CreatePostView.swift`.

---

## Data Models

### Supabase Schema (PostgreSQL)

```sql
users (
  id UUID PK,
  email TEXT UNIQUE NOT NULL,
  role TEXT CHECK ('parent' | 'child'),
  full_name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
  -- No single city column; see user_locations below
)

-- Users belong to many cities. Added via Map feature.
-- is_primary marks the city from onboarding.
user_locations (
  user_id UUID → users.id,
  city TEXT NOT NULL,
  location GEOGRAPHY(POINT, 4326),
  is_primary BOOL DEFAULT false,
  added_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, city)
)

skills ( id UUID PK, name TEXT UNIQUE )

user_skills (
  user_id UUID → users.id,
  skill_id UUID → skills.id,
  PRIMARY KEY (user_id, skill_id)
)

connections (
  id UUID PK,
  requester_id UUID → users.id,
  recipient_id UUID → users.id,
  status TEXT CHECK ('pending' | 'accepted' | 'declined' | 'blocked'),
  UNIQUE (requester_id, recipient_id)
)

-- intent drives color and sorting (seeking | offering).
-- subject is free text — it can be anything and grows over time
--   (e.g. "Housing", "Work", "Artwork", "Free Equipment", "Career Advice").
-- status controls visibility:
--   published  → live, visible to all
--   draft      → saved but not live; only visible to author
--   fulfilled  → completed/unpublished; only visible to author in their post history
posts (
  id UUID PK,
  author_id UUID → users.id,
  intent TEXT NOT NULL CHECK ('seeking' | 'offering'),
  subject TEXT NOT NULL,            -- open-ended, no DB constraint
  title TEXT NOT NULL,
  description TEXT,
  location TEXT NOT NULL,
  location_point GEOGRAPHY(POINT, 4326),
  status TEXT NOT NULL DEFAULT 'published' CHECK ('published' | 'draft' | 'fulfilled'),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
)

-- Suggested subjects table (soft list — not enforced on posts).
-- Populated by admins; drives autocomplete in CreatePostView.
post_subjects (
  id UUID PK,
  name TEXT UNIQUE NOT NULL    -- e.g. "Housing", "Work", "Artwork"
)

communities (
  id UUID PK,
  name TEXT,
  city TEXT,
  location GEOGRAPHY(POINT, 4326),
  member_count INT DEFAULT 0
)

community_members (
  community_id UUID → communities.id,
  user_id UUID → users.id,
  PRIMARY KEY (community_id, user_id)
)
```

**RLS Policies:**
- `users`: public SELECT, own-row UPDATE
- `user_locations`: public SELECT, own-rows INSERT/DELETE
- `posts`: `published` rows public SELECT; author SELECT on all their own statuses; author-only INSERT/UPDATE
- `connections`: SELECT only where `requester_id = auth.uid()` OR `recipient_id = auth.uid()`
- `post_subjects`: public SELECT (read-only for users; admin-managed)

**Indexes:** `user_locations(city)`, `user_locations(location)` GIST, `posts(intent)`, `posts(subject)`, `posts(status)`, `posts(location_point)` GIST, `connections(status)`

---

### Firestore Schema (Chat Only)

```
conversations/{conversationId}
  participants: [supabaseUserId, ...]
  lastMessage: string
  lastMessageAt: timestamp
  createdAt: timestamp

  messages/{messageId}
    senderId: string  (Supabase UUID)
    text: string
    createdAt: timestamp
    readBy: [userId, ...]
```

---

### Swift Models

```swift
// Supabase-backed
struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    let role: UserRole              // "parent" | "child"
    let fullName: String
    let avatarURL: String?
    let bio: String?
    var skills: [Skill]?
    var locations: [UserLocation]?  // joined; multiple cities supported
}

struct UserLocation: Codable {
    let city: String
    let isPrimary: Bool             // true for onboarding city
    let addedAt: Date
}

struct CommunityPost: Identifiable, Codable {
    let id: UUID
    let authorId: UUID
    let intent: PostIntent          // .seeking | .offering — drives color & sort
    let subject: String             // free text: "Housing", "Artwork", "Free Equipment", etc.
    let title: String
    let description: String?
    let location: String
    let status: PostStatus          // .published | .draft | .fulfilled
    let expiresAt: Date?
    var author: User?               // joined
}

struct Connection: Identifiable, Codable {
    let id: UUID
    let requesterId: UUID
    let recipientId: UUID
    let status: ConnectionStatus
}

struct MapCommunity: Identifiable {
    let id: UUID
    let name: String
    let memberCount: Int
    let members: [User]         // preview, first 5
    let coordinate: CLLocationCoordinate2D
}

// Firestore-backed
struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    let participants: [String]
    var lastMessage: String
    var lastMessageAt: Date
    let createdAt: Date
}

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    let senderId: String
    let text: String
    let createdAt: Date
    var readBy: [String]
}
```

### Enumerations

```swift
enum UserRole: String, Codable { case parent, child }

// The two stable states that drive all post UI. Subject is free text on the model.
enum PostIntent: String, Codable {
    case seeking, offering
    // cardColor: seeking → #F0D5B6  |  offering → #C9E3E7
    // tagColor:  seeking → #9D6402  |  offering → #146974
}

// Controls post visibility. Author can see all; public only sees .published.
enum PostStatus: String, Codable {
    case published  // live, visible to all
    case draft      // saved, only visible to author
    case fulfilled  // completed, unpublished; author can view in post history
}

enum ConnectionStatus: String, Codable { case pending, accepted, declined, blocked }

enum NavTab: Int, CaseIterable {
    case home        // house.fill       → CommunityView
    case inbox       // tray.fill        → InboxView
    case connections // person.2.fill    → ConnectionsView
    case map         // map.fill         → MapView
}
```

---

## State Management

All state classes use `@Observable` (iOS 17+ Observation framework). They are instantiated in `CommomityApp.swift` as `@State` properties and injected via `.environment()`. Views access them with `@Environment(ClassName.self)`.

```swift
// CommomityApp.swift — instantiation + injection
@State private var router = AppRouter()
@State private var onboardingState = OnboardingState()
@State private var session = UserSessionManager()
// .environment(router).environment(onboardingState).environment(session)

@Observable class OnboardingState {
    var selectedRole: UserRole? = nil
    var selectedSkills: Set<String> = []
    var selectedCity: String? = nil   // becomes the primary UserLocation on account creation
    var isComplete: Bool = false
    var canAdvanceFromSkills: Bool     // selectedSkills.isEmpty == false
    var canCompleteOnboarding: Bool    // selectedCity != nil
    func toggleSkill(_ skill: String)
    func addCustomSkill(_ skill: String)  // trims, dedupes, max 6
    func completeOnboarding()             // sets isComplete = true; TODO: write to Supabase
}

@Observable class UserSessionManager {
    var currentUser: User?
    var isAuthenticated: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil
    func signIn(email:password:) async
    func signUp(email:password:onboardingState:) async
    func signOut()
    func loadCurrentUser() async
}

@Observable class AppRouter {
    var selectedTab: NavTab = .home
    var navigationPath = NavigationPath()
    func handle(_ url: URL)   // Universal Links handler
    func navigateToProfile(userId:)
    func navigateToPost(postId:)
    func navigateToConversation(id:)
    func navigateToCommunity(id:)
    func goToCreatePost()
    func goToMyPosts()
}

// Route enum used with NavigationStack
enum Route: Hashable {
    case profile(String), postDetail(String), conversation(String)
    case communityDetail(String), createPost, myPosts
}

@Observable class ChatState {
    var conversations: [Conversation] = []
    var activeMessages: [Message] = []
    var isLoadingConversations: Bool = false
    var isLoadingMessages: Bool = false
    func fetchConversations(userId:) async
    func subscribeToMessages(conversationId:)
    func unsubscribeMessages()
    func sendMessage(conversationId:text:senderId:) async
    func createConversation(participants:) async -> String?
    // deinit calls unsubscribeMessages()
}
```

---

## UI Structure & Navigation

```
ContentView
├── onboardingState.isComplete == false → SignUpView
│     ├── RoleSelectionView    (step 1: tap Child or Parent → auto-advance)
│     ├── SkillSelectionView   (step 2: select 1–6 skills → Continue)
│     └── LocationSelectionView (step 3: pick city → Join Commomity)
│
└── onboardingState.isComplete == true → Main App (ZStack)
      ├── CommunityView    (tab: home)
      ├── InboxView        (tab: inbox)
      ├── ConnectionsView  (tab: connections)
      ├── MapView          (tab: map)
      └── BottomNavBar     (overlay)
```

**Deep link routing** via `AppRouter.handle(_ url: URL)` switches `selectedTab` and appends to `navigationPath`.

---

## Design System

### Colors
| Token | Hex | Usage |
|---|---|---|
| App Yellow | `#FFC14D` | Onboarding background, brand |
| Child Blue | `#4668FF` | Role selection |
| Parent Green | `#0CA609` | Role selection |
| Seeking Card | `#F0D5B6` | Post card background |
| Offering Card | `#C9E3E7` | Post card background |
| Seeking Tag | `#9D6402` | Tag label |
| Offering Tag | `#146974` | Tag label, location icon |
| Nav Bar | `#D9D9D9` | Bottom nav background |
| Nav Selected | `#5F61FF` @ 30% | Active tab highlight |
| Filter Pill | `#FCC8FF` | Community feed filters |
| Skill Selected | `#A6D3FF` bg / `#0150B0` shadow | Skill pill active state |
| Connection Blue | `#2700C2` | Connection role badge |
| Map Popup | `#676767` | Community popup card |

### Typography
| Font | Use |
|---|---|
| Playfair Display SemiBold/Bold | Titles, screen headers |
| Roboto Light/Regular/Medium/Bold | All body text, buttons, labels |

**Sizes:** 64pt (onboarding headline) → 44pt (role buttons) → 36pt (section titles) → 28pt (headers/buttons) → 24pt (names/search) → 20pt (tiles) → 16pt (tags/subtitles) → 14pt (metadata) → 12pt (previews)

### Spacing & Shape
- Screen corner radius: 28pt
- Card corner radius: 21pt
- Pill/button corner radius: 50pt
- Standard shadow: `color: .black.opacity(0.25), radius: 4, x: 0, y: 4`
- Pill shadow offset: black rectangle at (+3, +3)

### Reusable Components
| Component | File | Description |
|---|---|---|
| `BottomNavBar` | SharedComponents | 4-tab bar, 414×82.5pt, `#D9D9D9` bg, purple selected tint |
| `AvatarCircle` | SharedComponents | Circular avatar, configurable size (default 60pt), placeholder bg |
| `LocationLabel` | SharedComponents | Teal pin icon + city, 16pt Bold |
| `FilterPill` | SharedComponents | Tappable pill; `isSelected` + `action` params; selected state fills with `offeringTag` color |
| `SkillPillButton` | SharedComponents | Toggle pill with shadow offset; white→blue on select |
| `CommunityCard` | CommunityView | 109pt tall; bg from `post.intent.cardColorHex`; shows `title` + `"\(intent.label) \(subject)"` tag |
| `InboxRow` | InboxView | Avatar (single/group cluster), name, timestamp, optional `"\(intent.label) \(subject)"` tag |
| `ConnectionRow` | ConnectionsView | 73pt avatar, name, profession, location, role badge; uses `DisplayConnection` |
| `ExtendCommunityCard` | ConnectionsView | 87pt CTA card to invite contacts |
| `CommunityPopup` | MapView | Dark map popup with name, member count, 5 `DisplayConnection` member tiles, callout pointer |
| `AddCityConfirmationView` | MapView | Bottom sheet (240pt detent) to confirm adding a city to the user's profile |
| `HamburgerIcon` | SharedComponents | SF Symbol `line.3.horizontal.decrease`, decorative |
| `MyPostsView` | CreatePostView | Segmented picker (Published/Drafts/Fulfilled) over author's own posts |

---

## Onboarding Flow

### Step 1 — Role Selection (`RoleSelectionView`)
- Yellow bg, welcome headline (64pt shadow text), subtitle (24pt)
- Two buttons: "Child" (blue accent, 176×87pt) / "Parent" (green accent, 177×87pt)
- On tap: set `onboardingState.selectedRole` → auto-advance to step 2

### Step 2 — Skill Selection (`SkillSelectionView`)
- Yellow bg, headline (36pt), instruction subheading (16pt)
- Custom skill text input (pill shape, centered)
- Scrollable grid of `SkillPillButton` components
- Bottom row: "Continue" button (left, visible when ≥1 selected) + "X of 6" counter (right)
- Rules: min 1, max 6; custom skills auto-add and auto-select; no duplicates
- Predefined skills: Architecture, Government, Construction, Medicine, Tech, Finance, Teaching, Artwork, Business Management

### Step 3 — Location Selection (`LocationSelectionView`)
- Yellow bg, headline (36pt), subheading (16pt)
- Search bar (black shadow) + scrollable city list
- "Join Commomity" green button (visible when city selected)
- On tap: set `onboardingState.selectedCity`, set `isComplete = true` → navigate to main app
- This city is written as the user's **primary** `UserLocation` (`is_primary = true`) on account creation
- Additional cities are added later via the Map tab (no limit)
- Sample cities: San Francisco, Oakland, Berkeley, Petaluma, San Jose, Palo Alto, Mountain View, Fremont

---

## Current State & Roadmap

### What's implemented

| Area | Status | Notes |
|---|---|---|
| All UI views | ✅ Complete | CommunityView, InboxView, ConnectionsView, MapView, SignUpView |
| Models | ✅ Complete | New schema: `PostIntent`, `PostStatus`, `UserLocation`, `DisplayConnection`, Firestore models |
| State management | ✅ Complete | `OnboardingState`, `UserSessionManager`, `AppRouter`, `ChatState` — all `@Observable` |
| App entry + routing | ✅ Complete | `CommomityApp` injects state; Universal Links wired to `AppRouter.handle()` |
| Post creation UI | ✅ Complete | `CreatePostView` with intent toggle, subject picker, draft/publish actions |
| My Posts UI | ✅ Complete | `MyPostsView` with Published/Drafts/Fulfilled segmented view and post actions |
| Add City UI | ✅ Complete | `AddCityConfirmationView` sheet in MapView; confirm action is a stub |
| Service layer | ✅ Scaffolded | `SupabaseService`, `AuthenticationService`, `FirebaseService`, `LocationService` — all stubs with TODO comments |
| Supabase SDK | ❌ Not installed | Add via SPM: `https://github.com/supabase/supabase-swift` |
| Firebase SDK | ❌ Not installed | Add via SPM: `https://github.com/firebase/firebase-ios-sdk` |
| Real data | ❌ Not connected | All views use `SampleData` — replace calls with service layer once SDKs are added |

### SampleData contents
- `inboxMessages: [InboxMessage]` — 3 items (intent/subject instead of old tag)
- `communityPosts: [CommunityPost]` — 5 items (3 published, 1 draft, 1 fulfilled)
- `connections: [DisplayConnection]` — 2 items
- `mapCommunity: MapCommunity` — Petaluma, 5 unique members, real coordinates
- `skillFields: [String]` — 9 predefined skills
- `suggestedSubjects: [String]` — 10 subjects for post creation autocomplete

### Phase 1 (MVP — Next: SDK integration)
- Install Supabase Swift SDK → fill in `SupabaseService` and `AuthenticationService` stubs
- Install Firebase SDK → fill in `FirebaseService` and `ChatState` stubs
- Wire `UserSessionManager` to real Supabase Auth
- Replace all `SampleData` calls in views with live service calls
- Universal Links: configure Associated Domains entitlement + host AASA file at `commomity.app`

### Phase 2 (Core Features)
- Connections system (send/accept/decline/block, recommendations)
- Full chat UI in `ConversationView` (bubbles, typing indicators, image sharing, push notifications via APNs)
- Live MapKit: show user location, real community annotations from Supabase
- Full-text search (users, posts, communities via PostgreSQL `tsvector`)

### Phase 3 (Polish)
- SwiftData local caching for offline support
- Push notifications (APNs + Firestore Cloud Functions)
- Error/empty/loading states throughout all views
- Accessibility (VoiceOver, Dynamic Type, haptics)
- Image caching, list lazy loading, search debounce (300ms)

### Phase 4 (Advanced)
- Firebase Analytics + Crashlytics
- Content moderation & reporting
- Skill/location-based recommendations engine
- Internationalization (en, es, zh)

---

## Universal Links

Domain: `commomity.app`

| URL Pattern | Destination |
|---|---|
| `/user/{userId}` | Profile view |
| `/post/{postId}` | Post detail, switches to home tab |
| `/conversation/{conversationId}` | Chat, switches to inbox tab |
| `/community/{communityId}` | Community detail, switches to map tab |
| `/invite/{code}` | Invite acceptance flow |

Associated Domains entitlement: `applinks:commomity.app`, `applinks:www.commomity.app`
AASA file hosted at: `https://commomity.app/.well-known/apple-app-site-association`
