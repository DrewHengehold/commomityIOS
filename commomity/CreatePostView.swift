import SwiftUI

// MARK: - CreatePostView

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PostStore.self) private var postStore
    @Environment(UserSessionManager.self) private var session

    @State private var intent: PostIntent = .seeking
    @State private var subject: String = ""
    @State private var customSubject: Bool = false
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var location: String = ""
    @State private var isSaving: Bool = false

    // MARK: Validation

    private var canPublish: Bool {
        !subject.isEmpty && !title.isEmpty && !location.isEmpty
    }

    private var canSaveDraft: Bool {
        !title.isEmpty
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // ── 1. Header ──────────────────────────────────────
                    headerRow

                    // ── 2. Intent toggle ──────────────────────────────
                    intentToggle

                    // ── 3. Subject picker ─────────────────────────────
                    subjectPicker

                    // ── 4. Title field ────────────────────────────────
                    titleField

                    // ── 5. Description field ──────────────────────────
                    descriptionField

                    // ── 6. Location field ─────────────────────────────
                    locationField

                    // Bottom padding so content clears the action bar
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
            }

            // ── 7. Bottom action area ──────────────────────────────
            actionBar
        }
    }

    // MARK: - Sub-views

    // 1. Header row
    private var headerRow: some View {
        HStack(alignment: .center) {
            Text("New Post")
                .font(AppTheme.Fonts.playfair(28))
                .foregroundColor(.black)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color(hex: "#F0F0F0"))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // 2. Intent toggle — two large pill buttons
    private var intentToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("I am...")
                .font(AppTheme.Fonts.roboto(13, weight: .medium))
                .foregroundColor(AppTheme.Colors.subtitleGray)

            HStack(spacing: 12) {
                ForEach([PostIntent.seeking, PostIntent.offering], id: \.rawValue) { option in
                    intentPillButton(for: option)
                }
            }
        }
    }

    private func intentPillButton(for option: PostIntent) -> some View {
        let isSelected = intent == option
        let tagColor = Color(hex: option.tagColorHex)

        return Button {
            intent = option
        } label: {
            Text(option.label)
                .font(AppTheme.Fonts.roboto(18, weight: .bold))
                .foregroundColor(isSelected ? .white : .black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.pillRadius)
                        .fill(isSelected ? tagColor : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.pillRadius)
                                .strokeBorder(isSelected ? Color.clear : Color(hex: "#D8D8D8"), lineWidth: 1.5)
                        )
                )
                .shadow(color: isSelected ? tagColor.opacity(0.35) : Color.black.opacity(0.08),
                        radius: isSelected ? 6 : 3, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: intent)
    }

    // 3. Subject picker
    private var subjectPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Subject")
                .font(AppTheme.Fonts.roboto(13, weight: .medium))
                .foregroundColor(AppTheme.Colors.subtitleGray)

            // Horizontal scroll of subject pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SampleData.suggestedSubjects, id: \.self) { suggested in
                        SubjectPill(
                            label: suggested,
                            isSelected: subject == suggested && !customSubject
                        ) {
                            subject = suggested
                            customSubject = false
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Custom subject text field
            HStack(spacing: 10) {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.subtitleGray)
                TextField("or type your own...", text: Binding(
                    get: { customSubject ? subject : "" },
                    set: { newValue in
                        subject = newValue
                        customSubject = !newValue.isEmpty
                    }
                ))
                .font(AppTheme.Fonts.roboto(15))
                .foregroundColor(.black)
                .onTapGesture {
                    customSubject = true
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(
                RoundedRectangle(cornerRadius: 50)
                    .strokeBorder(
                        customSubject && !subject.isEmpty
                            ? Color(hex: intent.tagColorHex)
                            : Color(hex: "#D8D8D8"),
                        lineWidth: customSubject && !subject.isEmpty ? 2 : 1.5
                    )
            )
        }
    }

    // 4. Title field
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(AppTheme.Fonts.roboto(13, weight: .medium))
                .foregroundColor(AppTheme.Colors.subtitleGray)

            TextField("What do you need or offer?", text: $title)
                .font(AppTheme.Fonts.roboto(16))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 50)
                        .strokeBorder(
                            title.isEmpty ? Color(hex: "#D8D8D8") : Color(hex: intent.tagColorHex),
                            lineWidth: title.isEmpty ? 1.5 : 2
                        )
                )
        }
    }

    // 5. Description field (multi-line)
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(AppTheme.Fonts.roboto(13, weight: .medium))
                .foregroundColor(AppTheme.Colors.subtitleGray)

            ZStack(alignment: .topLeading) {
                // Placeholder
                if description.isEmpty {
                    Text("Add details...")
                        .font(AppTheme.Fonts.roboto(16))
                        .foregroundColor(Color(hex: "#A5A5A5"))
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $description)
                    .font(AppTheme.Fonts.roboto(16))
                    .foregroundColor(.black)
                    .frame(height: 96)
                    .padding(.horizontal, 12)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        description.isEmpty ? Color(hex: "#D8D8D8") : Color(hex: intent.tagColorHex),
                        lineWidth: description.isEmpty ? 1.5 : 2
                    )
            )
        }
    }

    // 6. Location field
    private var locationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(AppTheme.Fonts.roboto(13, weight: .medium))
                .foregroundColor(AppTheme.Colors.subtitleGray)

            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.offeringTag)
                TextField("City", text: $location)
                    .font(AppTheme.Fonts.roboto(16))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 50)
                    .strokeBorder(
                        location.isEmpty ? Color(hex: "#D8D8D8") : Color(hex: intent.tagColorHex),
                        lineWidth: location.isEmpty ? 1.5 : 2
                    )
            )
        }
    }

    // 7. Bottom action bar
    private var actionBar: some View {
        HStack(spacing: 14) {
            // Save Draft
            Button {
                saveDraft()
            } label: {
                Text("Save Draft")
                    .font(AppTheme.Fonts.roboto(16, weight: .bold))
                    .foregroundColor(canSaveDraft ? .black : Color(hex: "#ABABAB"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.pillRadius)
                            .fill(canSaveDraft ? Color(hex: "#E8E8E8") : Color(hex: "#F5F5F5"))
                    )
            }
            .disabled(!canSaveDraft || isSaving)
            .buttonStyle(.plain)

            // Publish
            Button {
                publishPost()
            } label: {
                HStack(spacing: 6) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text("Publish")
                        .font(AppTheme.Fonts.roboto(16, weight: .bold))
                        .foregroundColor(canPublish ? .white : Color.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.pillRadius)
                        .fill(canPublish ? AppTheme.Colors.offeringTag : AppTheme.Colors.offeringTag.opacity(0.45))
                )
            }
            .disabled(!canPublish || isSaving)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 32)
        .padding(.top, 12)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: -4)
        )
    }

    // MARK: - Actions

    private func saveDraft() {
        guard let authorId = session.currentUserId else { return }
        isSaving = true
        Task {
            await postStore.saveDraft(
                intent: intent,
                subject: subject,
                title: title,
                description: description,
                location: location,
                authorId: authorId
            )
            isSaving = false
            dismiss()
        }
    }

    private func publishPost() {
        guard let authorId = session.currentUserId else { return }
        isSaving = true
        Task {
            await postStore.publish(
                intent: intent,
                subject: subject,
                title: title,
                description: description,
                location: location,
                authorId: authorId
            )
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - SubjectPill (local, sized for this form)

private struct SubjectPill: View {
    let label: String
    var isSelected: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppTheme.Fonts.roboto(15, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .black)
                .padding(.horizontal, 16)
                .frame(height: 34)
                .background(
                    ZStack {
                        // Offset shadow pill
                        RoundedRectangle(cornerRadius: 50)
                            .fill(isSelected ? AppTheme.Colors.selectedPillShadow : Color.black)
                            .offset(x: 2, y: 2)
                        // Main pill
                        RoundedRectangle(cornerRadius: 50)
                            .fill(isSelected ? AppTheme.Colors.selectedPillBg : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 50)
                                    .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
                            )
                    }
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - MyPostsView

struct MyPostsView: View {
    @State private var selectedStatus: PostStatus = .published

    var filteredPosts: [CommunityPost] {
        SampleData.communityPosts.filter { $0.status == selectedStatus }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // Title
                HStack {
                    Text("My Posts")
                        .font(AppTheme.Fonts.playfair(28))
                        .foregroundColor(.black)
                        .padding(.leading, 22)
                    Spacer()
                }
                .padding(.top, 16)

                // Segmented control
                Picker("Status", selection: $selectedStatus) {
                    ForEach(PostStatus.allCases, id: \.self) { status in
                        Text(status.displayLabel).tag(status)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 10)

                // Divider
                Rectangle()
                    .fill(Color.black.opacity(0.08))
                    .frame(height: 1)
                    .padding(.horizontal, 22)

                // Posts or empty state
                if filteredPosts.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            ForEach(filteredPosts) { post in
                                MyPostCard(post: post, status: selectedStatus)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
    }

    // Empty state view
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundColor(AppTheme.Colors.subtitleGray.opacity(0.5))
            Text("No \(selectedStatus.displayLabel.lowercased()) posts yet.")
                .font(AppTheme.Fonts.roboto(18, weight: .medium))
                .foregroundColor(AppTheme.Colors.subtitleGray)
            Spacer()
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - MyPostCard

private struct MyPostCard: View {
    let post: CommunityPost
    let status: PostStatus

    private var cardBg: Color { Color(hex: post.intent.cardColorHex) }
    private var tagColor: Color { Color(hex: post.intent.tagColorHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Reuse CommunityCard layout
            CommunityCard(post: post)

            // Status-specific action button
            if status == .draft || status == .published {
                HStack {
                    Spacer()
                    actionButton
                        .padding(.trailing, 12)
                        .padding(.bottom, 10)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .fill(cardBg)
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
        )
        // Override CommunityCard's own background to avoid double-shadow
        .compositingGroup()
    }

    @ViewBuilder
    private var actionButton: some View {
        switch status {
        case .draft:
            Button {
                print("TODO: Publish draft post id: \(post.id)")
            } label: {
                Label("Publish", systemImage: "arrow.up.circle.fill")
                    .font(AppTheme.Fonts.roboto(14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 50)
                            .fill(AppTheme.Colors.offeringTag)
                    )
            }
            .buttonStyle(.plain)

        case .published:
            Button {
                print("TODO: Mark post fulfilled id: \(post.id)")
            } label: {
                Label("Mark Fulfilled", systemImage: "checkmark.circle.fill")
                    .font(AppTheme.Fonts.roboto(14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 50)
                            .fill(Color(hex: "#4CAF50"))
                    )
            }
            .buttonStyle(.plain)

        default:
            EmptyView()
        }
    }
}

// MARK: - Previews

#Preview("Create Post") {
    struct Preview: View {
        @State var postStore = PostStore()
        @State var session = UserSessionManager()
        var body: some View {
            CreatePostView()
                .environment(postStore)
                .environment(session)
        }
    }
    return Preview()
}

#Preview("My Posts - Published") {
    MyPostsView()
}

#Preview("My Posts - Drafts") {
    struct DraftPreview: View {
        @State private var v = MyPostsView()
        var body: some View { MyPostsView() }
    }
    return DraftPreview()
}
