import SwiftUI

// MARK: - Sign Up Step 1: Role Selection
struct SignUpView: View {
    @State private var selectedRole: UserRole? = nil
    @State private var navigateToSkills = false

    enum UserRole { case child, parent }

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
                        .offset(x: 2, y: 2)
                    Text("Welcome to Commomity")
                        .font(AppTheme.Fonts.roboto(64, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .lineSpacing(2)

                Text("an app built for the parent network")
                    .font(AppTheme.Fonts.roboto(24, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
                    .padding(.top, 16)

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
                        selectedRole = .child
                        navigateToSkills = true
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
                        selectedRole = .parent
                        navigateToSkills = true
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
                .padding(.top, 20)

                Spacer()
            }
        }
        .fullScreenCover(isPresented: $navigateToSkills) {
            SkillSelectionView()
        }
    }
}

// MARK: - Sign Up Step 2: Skill Selection
struct SkillSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedSkills: Set<String> = ["Teaching"] // pre-select one per design
    @State private var customSkill = ""
    let maxSelections = 3

    // Layout the pills in rows matching the design
    private let skillRows: [[String]] = [
        ["Architecture", "Government"],
        ["Construction", "Medicine"],
        ["Tech", "Finance"],
        ["Teaching", "Artwork"],
        ["Business Management"]
    ]

    var body: some View {
        ZStack {
            AppTheme.Colors.appYellow.ignoresSafeArea()

            VStack(spacing: 0) {

                // Headline (shadow effect)
                ZStack {
                    Text("Choose 3 fields you're well connected in!")
                        .font(AppTheme.Fonts.roboto(36, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .offset(x: -2, y: -1)
                    Text("Choose 3 fields you're well connected in!")
                        .font(AppTheme.Fonts.roboto(36, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 36)
                .padding(.top, 12)

                // Subheading
                Text("Help your community get to know you! Choose 3 fields you're well connected in!")
                    .font(AppTheme.Fonts.roboto(16, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 45)
                    .padding(.top, 8)

                // Custom skill pill (text input)
                ZStack {
                    RoundedRectangle(cornerRadius: 50)
                        .fill(Color.white)
                    RoundedRectangle(cornerRadius: 50)
                        .fill(Color.black)
                        .offset(x: 3, y: 3)
                    RoundedRectangle(cornerRadius: 50)
                        .fill(Color.white)
                    TextField("Design your own..", text: $customSkill)
                        .font(AppTheme.Fonts.roboto(24))
                        .multilineTextAlignment(.center)
                }
                .frame(width: 279, height: 39)
                .padding(.top, 20)

                // Skill grid
                VStack(spacing: 10) {
                    ForEach(skillRows, id: \.self) { row in
                        HStack(spacing: 10) {
                            ForEach(row, id: \.self) { skill in
                                SkillPillButton(
                                    label: skill,
                                    isSelected: selectedSkills.contains(skill)
                                ) {
                                    toggleSkill(skill)
                                }
                                .frame(height: 39)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 16)

                Spacer()

                // Progress indicator
                HStack {
                    Spacer()
                    ZStack {
                        Text("1 of 3")
                            .font(AppTheme.Fonts.roboto(36, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: -2, y: -1)
                        Text("1 of 3")
                            .font(AppTheme.Fonts.roboto(36, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.trailing, 35)
                    .padding(.bottom, 31)
                }
            }
        }
    }

    private func toggleSkill(_ skill: String) {
        if selectedSkills.contains(skill) {
            selectedSkills.remove(skill)
        } else if selectedSkills.count < maxSelections {
            selectedSkills.insert(skill)
        }
    }
}

#Preview {
    SignUpView()
}
