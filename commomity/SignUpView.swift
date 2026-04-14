import SwiftUI
import AuthenticationServices
import CryptoKit

// MARK: - Sign Up Container (all onboarding steps)
struct SignUpView: View {
    @Environment(OnboardingState.self) private var onboardingState
    @State private var currentStep: OnboardingStep = .accountCreation

    enum OnboardingStep {
        case accountCreation
        case roleSelection
        case skillSelection
        case locationSelection
    }

    var body: some View {
        ZStack {
            switch currentStep {
            case .accountCreation:
                AccountCreationView(currentStep: $currentStep)
            case .roleSelection:
                RoleSelectionView(currentStep: $currentStep)
            case .skillSelection:
                SkillSelectionView(currentStep: $currentStep)
            case .locationSelection:
                LocationSelectionView()
            }
        }
        .animation(.easeInOut, value: currentStep)
    }
}

// MARK: - Sign Up Step 0: Account Creation / Sign In
struct AccountCreationView: View {
    @Environment(OnboardingState.self) private var onboardingState
    @Environment(UserSessionManager.self) private var session
    @Binding var currentStep: SignUpView.OnboardingStep

    @State private var isSignIn = false
    @State private var confirmPassword = ""
    @State private var localError = ""
    @State private var currentNonce: String?
    @Environment(\.openURL) private var openURL

    private var displayError: String {
        localError.isEmpty ? (session.errorMessage ?? "") : localError
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.appYellow.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Title
                    ZStack {
                        Text(isSignIn ? "Welcome Back" : "Create Your Account")
                            .font(AppTheme.Fonts.roboto(44, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .offset(x: 2, y: 2)
                        Text(isSignIn ? "Welcome Back" : "Create Your Account")
                            .font(AppTheme.Fonts.roboto(44, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 80)

                    Text(isSignIn ? "Sign in to your Commomity account" : "Join the Commomity parent network")
                        .font(AppTheme.Fonts.roboto(18, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 12)

                    // Sign Up / Sign In toggle pill
                    HStack(spacing: 0) {
                        ForEach(["Sign Up", "Sign In"], id: \.self) { label in
                            let selected = (label == "Sign In") == isSignIn
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isSignIn = label == "Sign In"
                                }
                                localError = ""
                                session.errorMessage = nil
                            } label: {
                                Text(label)
                                    .font(AppTheme.Fonts.roboto(18, weight: .bold))
                                    .foregroundColor(selected ? .black : AppTheme.Colors.subtitleGray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 50)
                                            .fill(selected ? Color.white : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 50)
                            .fill(Color.black.opacity(0.12))
                    )
                    .padding(.horizontal, 30)
                    .padding(.top, 28)
                    

                    // Social auth buttons
                    VStack(spacing: 12) {
                        // Apple
                        // Note: Add "Sign in with Apple" capability in
                        // Xcode → Signing & Capabilities before shipping.
                        SignInWithAppleButton(isSignIn ? .signIn : .signUp) { request in
                            let nonce = randomNonceString()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        } onCompletion: { result in
                            handleAppleCompletion(result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 55)
                        .clipShape(RoundedRectangle(cornerRadius: 50))
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 3, y: 3)

                        // Google
                        Button {
                            handleGoogleSignIn()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50)
                                    .fill(Color.black)
                                    .offset(x: 3, y: 3)
                                RoundedRectangle(cornerRadius: 50)
                                    .fill(Color.white)
                                HStack(spacing: 10) {
                                    Text("G")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(Color(hex: "#4285F4"))
                                    Text("Continue with Google")
                                        .font(AppTheme.Fonts.roboto(18, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            }
                            .frame(height: 55)
                        }
                        .buttonStyle(.plain)
                        .disabled(session.isLoading)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color.black.opacity(0.25))
                            .frame(height: 1)
                        Text("or continue with")
                            .font(AppTheme.Fonts.roboto(14, weight: .bold))
                            .foregroundColor(.black.opacity(0.55))
                            .fixedSize()
                        Rectangle()
                            .fill(Color.black.opacity(0.25))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 24)


                    // Fields
                    VStack(spacing: 14) {
                        if !isSignIn {
                            OnboardingTextField(
                                placeholder: "Full Name",
                                text: Bindable(onboardingState).fullName
                            )
                        }

                        OnboardingTextField(
                            placeholder: "Email Address",
                            text: Bindable(onboardingState).email,
                            keyboardType: .emailAddress
                        )

                        OnboardingTextField(
                            placeholder: isSignIn ? "Password" : "Password (min 6 characters)",
                            text: Bindable(onboardingState).password,
                            isSecure: true
                        )

                        if !isSignIn {
                            OnboardingTextField(
                                placeholder: "Confirm Password",
                                text: $confirmPassword,
                                isSecure: true
                            )
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 24)

                    // Error
                    if !displayError.isEmpty {
                        Text(displayError)
                            .font(AppTheme.Fonts.roboto(14))
                            .foregroundColor(.red)
                            .padding(.top, 10)
                            .padding(.horizontal, 30)
                            .multilineTextAlignment(.center)
                    }

                    // Action button
                    Button {
                        handleAuth()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 50)
                                .fill(Color.black)
                                .offset(x: 3, y: 3)
                            RoundedRectangle(cornerRadius: 50)
                                .fill(Color.white)
                            if session.isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Text(isSignIn ? "Sign In" : "Continue")
                                    .font(AppTheme.Fonts.roboto(24, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(width: 220, height: 55)
                    }
                    .buttonStyle(.plain)
                    .disabled(session.isLoading)
                    .padding(.top, 32)
                    .padding(.bottom, 60)

                }
            }
        }
        .onChange(of: session.isAuthenticated) { _, isAuth in
            guard isAuth else { return }
            if isSignIn {
                // Returning user — profile already exists, skip onboarding
                onboardingState.isComplete = true
            } else {
                // New user — continue to role selection
                withAnimation { currentStep = .roleSelection }
            }
        }
    }

    private func handleAuth() {
        localError = ""
        session.errorMessage = nil

        if isSignIn {
            guard !onboardingState.email.isEmpty, !onboardingState.password.isEmpty else {
                localError = "Please enter your email and password."
                return
            }
            Task {
                await session.signIn(email: onboardingState.email, password: onboardingState.password)
            }
        } else {
            guard validateSignUp() else { return }
            Task {
                await session.signUp(
                    email: onboardingState.email,
                    password: onboardingState.password,
                    fullName: onboardingState.fullName,
                    onboardingState: onboardingState
                )
            }
        }
    }

    @discardableResult
    private func validateSignUp() -> Bool {
        if onboardingState.fullName.trimmingCharacters(in: .whitespaces).isEmpty {
            localError = "Please enter your full name."
        } else if !onboardingState.email.contains("@") || !onboardingState.email.contains(".") {
            localError = "Please enter a valid email address."
        } else if onboardingState.password.count < 6 {
            localError = "Password must be at least 6 characters."
        } else if onboardingState.password != confirmPassword {
            localError = "Passwords do not match."
        } else {
            return true
        }
        return false
    }

    // MARK: - Apple Sign In
    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let idTokenData = credential.identityToken,
                let idToken = String(data: idTokenData, encoding: .utf8),
                let nonce = currentNonce
            else {
                localError = "Apple Sign In failed. Please try again."
                return
            }
            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }.joined(separator: " ")
            Task {
                await session.signInWithApple(
                    idToken: idToken,
                    nonce: nonce,
                    fullName: fullName.isEmpty ? nil : fullName,
                    email: credential.email
                )
            }
        case .failure(let error):
            // ASAuthorizationError.canceled (code 1001) means user dismissed — don't show an error
            let asError = error as? ASAuthorizationError
            if asError?.code != .canceled {
                localError = error.localizedDescription
            }
        }
    }

    // MARK: - Google Sign In
    private func handleGoogleSignIn() {
        localError = ""
        session.errorMessage = nil
        Task {
            if let url = await session.googleSignInURL() {
                await MainActor.run { openURL(url) }
            }
        }
    }
}

// MARK: - Reusable onboarding text field
struct OnboardingTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words
    var isSecure: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 50)
                .fill(Color.black)
                .offset(x: 3, y: 3)
            RoundedRectangle(cornerRadius: 50)
                .fill(Color.white)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                        .autocorrectionDisabled(keyboardType == .emailAddress)
                }
            }
            .font(AppTheme.Fonts.roboto(18))
            .padding(.horizontal, 20)
        }
        .frame(height: 52)
    }
}

// MARK: - Role Selection View
struct RoleSelectionView: View {
    @Environment(OnboardingState.self) private var onboardingState
    @Binding var currentStep: SignUpView.OnboardingStep

    var body: some View {
        ZStack {
            AppTheme.Colors.appYellow.ignoresSafeArea()

            VStack(spacing: 0) {
                // Welcome title (shadow white + black layered)
                ZStack {
                    Text("Welcome to Commomity")
                        .font(AppTheme.Fonts.roboto(64, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .offset(x: 2, y: 2)
                    Text("Welcome to Commomity")
                        .font(AppTheme.Fonts.roboto(64, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 25)
                .padding(.top, 113)

                Text("an app built for the parent network")
                    .font(AppTheme.Fonts.roboto(24, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
                    .padding(.top, 18)

                Spacer()

                // "Are you a" prompt
                ZStack {
                    Text("Are you a")
                        .font(AppTheme.Fonts.roboto(44, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: -2, y: -1)
                    Text("Are you a")
                        .font(AppTheme.Fonts.roboto(44, weight: .bold))
                        .foregroundColor(.black)
                }

                // Role buttons
                HStack(spacing: 0) {
                    // Child
                    Button {
                        onboardingState.selectedRole = .child
                        withAnimation {
                            currentStep = .skillSelection
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 50)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.25), radius: 4.5, x: 5, y: 5)
                            Text("Child")
                                .font(AppTheme.Fonts.roboto(44, weight: .bold))
                                .foregroundColor(AppTheme.Colors.childBlue)
                        }
                        .frame(width: 176, height: 87)
                    }
                    .buttonStyle(.plain)

                    // "or" separator
                    Text("or")
                        .font(.custom("PlayfairDisplay-Bold", size: 44))
                        .foregroundColor(.white)
                        .frame(width: 98)

                    // Parent
                    Button {
                        onboardingState.selectedRole = .parent
                        withAnimation {
                            currentStep = .skillSelection
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 50)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.25), radius: 4.5, x: 5, y: 5)
                            Text("Parent")
                                .font(AppTheme.Fonts.roboto(44, weight: .bold))
                                .foregroundColor(AppTheme.Colors.parentGreen)
                        }
                        .frame(width: 177, height: 87)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 24)

                Spacer()
            }
        }
    }
}

// MARK: - Sign Up Step 2: Skill Selection
struct SkillSelectionView: View {
    @Environment(OnboardingState.self) private var onboardingState
    @Binding var currentStep: SignUpView.OnboardingStep
    @State private var customSkills: [String] = []
    @State private var customSkill = ""
    let maxSelections = 6

    // Layout the pills in rows matching the design
    private var skillRows: [[String]] {
        var rows: [[String]] = [
            ["Architecture", "Government"],
            ["Construction", "Medicine"],
            ["Tech", "Finance"],
            ["Teaching", "Artwork"],
            ["Business Management"]
        ]

        // Add custom skills to the grid
        if !customSkills.isEmpty {
            rows.append(customSkills)
        }

        return rows
    }

    private var canProceed: Bool {
        onboardingState.selectedSkills.count >= 1 && onboardingState.selectedSkills.count <= maxSelections
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.appYellow.ignoresSafeArea()

            VStack(spacing: 0) {

                // Headline (shadow effect)
                ZStack {
                    Text("Choose up to 6 fields you're well connected in!")
                        .font(AppTheme.Fonts.roboto(36, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .offset(x: -2, y: -1)
                    Text("Choose up to 6 fields you're well connected in!")
                        .font(AppTheme.Fonts.roboto(36, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 36)
                .padding(.top, 74)

                // Subheading
                Text("Help your community get to know you! Choose up to 6 fields you're well connected in!")
                    .font(AppTheme.Fonts.roboto(16, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 45)
                    .padding(.top, 8)

                // Custom skill pill (text input)
                ZStack {
                    RoundedRectangle(cornerRadius: 50)
                        .fill(Color.black)
                        .offset(x: 3, y: 3)
                    RoundedRectangle(cornerRadius: 50)
                        .fill(Color.white)
                    TextField("Design your own..", text: $customSkill)
                        .font(AppTheme.Fonts.roboto(24))
                        .multilineTextAlignment(.center)
                        .submitLabel(.done)
                        .onSubmit {
                            addCustomSkill()
                        }
                }
                .frame(width: 279, height: 39)
                .padding(.top, 20)

                // Skill grid
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(skillRows, id: \.self) { row in
                            HStack(spacing: 10) {
                                ForEach(row, id: \.self) { skill in
                                    SkillPillButton(
                                        label: skill,
                                        isSelected: onboardingState.selectedSkills.contains(skill)
                                    ) {
                                        toggleSkill(skill)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 16)

                Spacer()

                // Continue button and progress indicator
                HStack {
                    // Continue button (left side)
                    if canProceed {
                        Button {
                            withAnimation {
                                currentStep = .locationSelection
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50)
                                    .fill(Color.black)
                                    .offset(x: 3, y: 3)
                                RoundedRectangle(cornerRadius: 50)
                                    .fill(Color.white)
                                Text("Continue")
                                    .font(AppTheme.Fonts.roboto(24, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            .frame(width: 160, height: 50)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 35)
                    }

                    Spacer()

                    // Progress indicator (right side)
                    ZStack {
                        Text("\(onboardingState.selectedSkills.count) of 6")
                            .font(AppTheme.Fonts.roboto(36, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: -2, y: -1)
                        Text("\(onboardingState.selectedSkills.count) of 6")
                            .font(AppTheme.Fonts.roboto(36, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.trailing, 35)
                }
                .padding(.bottom, 31)
            }
        }
    }

    private func toggleSkill(_ skill: String) {
        if onboardingState.selectedSkills.contains(skill) {
            onboardingState.selectedSkills.remove(skill)
        } else if onboardingState.selectedSkills.count < maxSelections {
            onboardingState.selectedSkills.insert(skill)
        }
    }

    private func addCustomSkill() {
        let trimmedSkill = customSkill.trimmingCharacters(in: .whitespaces)

        guard !trimmedSkill.isEmpty else { return }
        guard !customSkills.contains(trimmedSkill) else {
            customSkill = ""
            return
        }

        customSkills.append(trimmedSkill)

        if onboardingState.selectedSkills.count < maxSelections {
            onboardingState.selectedSkills.insert(trimmedSkill)
        }

        customSkill = ""
    }
}

// MARK: - Sign Up Step 3: Location Selection
struct LocationSelectionView: View {
    @Environment(OnboardingState.self) private var onboardingState
    @State private var searchText = ""
    @State private var selectedCity: String? = nil

    // Sample cities near the user
    let nearbyCities = [
        "San Francisco", "Oakland", "Berkeley", "Petaluma",
        "San Jose", "Palo Alto", "Mountain View", "Fremont"
    ]

    var filteredCities: [String] {
        if searchText.isEmpty {
            return nearbyCities
        } else {
            return nearbyCities.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.appYellow.ignoresSafeArea()

            VStack(spacing: 0) {

                // Headline (shadow effect)
                ZStack {
                    Text("Where is your community?")
                        .font(AppTheme.Fonts.roboto(36, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .offset(x: -2, y: -1)
                    Text("Where is your community?")
                        .font(AppTheme.Fonts.roboto(36, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 36)
                .padding(.top, 74)

                // Subheading
                Text("Select your city to connect with parents nearby!")
                    .font(AppTheme.Fonts.roboto(16, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 45)
                    .padding(.top, 8)

                // Search bar
                ZStack {
                    RoundedRectangle(cornerRadius: 50)
                        .fill(Color.black)
                        .offset(x: 3, y: 3)
                    RoundedRectangle(cornerRadius: 50)
                        .fill(Color.white)
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#8C8C8C"))
                        TextField("Search for your city...", text: $searchText)
                            .font(AppTheme.Fonts.roboto(20))
                    }
                    .padding(.horizontal, 20)
                }
                .frame(width: 330, height: 44)
                .padding(.top, 24)

                // Cities list
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(filteredCities, id: \.self) { city in
                            Button {
                                selectedCity = city
                                onboardingState.selectedCity = city
                            } label: {
                                ZStack {
                                    if selectedCity == city {
                                        RoundedRectangle(cornerRadius: 50)
                                            .fill(AppTheme.Colors.selectedPillShadow)
                                            .offset(x: 3, y: 3)
                                    } else {
                                        RoundedRectangle(cornerRadius: 50)
                                            .fill(Color.black)
                                            .offset(x: 3, y: 3)
                                    }
                                    RoundedRectangle(cornerRadius: 50)
                                        .fill(selectedCity == city ? AppTheme.Colors.selectedPillBg : Color.white)

                                    HStack(spacing: 8) {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(AppTheme.Colors.offeringTag)
                                        Text(city)
                                            .font(AppTheme.Fonts.roboto(24, weight: selectedCity == city ? .bold : .medium))
                                            .foregroundColor(.black)
                                    }
                                }
                                .frame(width: 330, height: 50)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 24)
                }

                Spacer()

                // Complete button
                if selectedCity != nil {
                    Button {
                        completeOnboarding()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 50)
                                .fill(Color.black)
                                .offset(x: 3, y: 3)
                            RoundedRectangle(cornerRadius: 50)
                                .fill(AppTheme.Colors.parentGreen)
                            Text("Join Commomity")
                                .font(AppTheme.Fonts.roboto(28, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 280, height: 60)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func completeOnboarding() {
        onboardingState.isComplete = true
    }
}

// MARK: - Apple Sign In Nonce Helpers

/// Generates a cryptographically random nonce string for Apple Sign In.
private func randomNonceString(length: Int = 32) -> String {
    var randomBytes = [UInt8](repeating: 0, count: length)
    let _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    return String(randomBytes.map { charset[Int($0) % charset.count] })
}

/// Returns the SHA256 hex digest of the input — used to hash the nonce before sending to Apple.
private func sha256(_ input: String) -> String {
    let data = Data(input.utf8)
    let hash = SHA256.hash(data: data)
    return hash.map { String(format: "%02x", $0) }.joined()
}

// MARK: - Previews

#Preview("Sign Up - Account Creation") {
    struct Preview: View {
        @State var state = OnboardingState()
        @State var session = UserSessionManager()
        var body: some View {
            SignUpView()
                .environment(state)
                .environment(session)
        }
    }
    return Preview()
}

#Preview("Sign Up - Role Selection") {
    struct Preview: View {
        @State var state = OnboardingState()
        var body: some View {
            RoleSelectionView(currentStep: .constant(.roleSelection))
                .environment(state)
        }
    }
    return Preview()
}

#Preview("Skill Selection") {
    struct Preview: View {
        @State var state = OnboardingState()
        var body: some View {
            SkillSelectionView(currentStep: .constant(.skillSelection))
                .environment(state)
        }
    }
    return Preview()
}

#Preview("Location Selection") {
    struct Preview: View {
        @State var state = OnboardingState()
        var body: some View {
            LocationSelectionView()
                .environment(state)
        }
    }
    return Preview()
}
