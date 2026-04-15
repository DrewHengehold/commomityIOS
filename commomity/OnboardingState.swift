import Foundation
import Observation

@Observable
class OnboardingState {

    // MARK: - Auth credentials (step 0: AccountCreationView)
    var fullName: String = ""
    var email: String = ""
    var password: String = ""

    // MARK: - Profile data (steps 1–3)
    var selectedRole: UserRole? = nil
    var selectedSkills: Set<String> = []
    var selectedCity: String? = nil

    // MARK: - Completion flag (persisted across launches)
    var isComplete: Bool = false

    // MARK: - Validation

    var canAdvanceFromSkills: Bool { !selectedSkills.isEmpty }
    var canCompleteOnboarding: Bool { selectedCity != nil }

    // MARK: - Skill helpers

    func toggleSkill(_ skill: String) {
        if selectedSkills.contains(skill) {
            selectedSkills.remove(skill)
        } else if selectedSkills.count < 6 {
            selectedSkills.insert(skill)
        }
    }

    func addCustomSkill(_ skill: String) {
        let trimmed = skill.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !selectedSkills.contains(trimmed),
              selectedSkills.count < 6 else { return }
        selectedSkills.insert(trimmed)
    }

    // MARK: - Completion

    func completeOnboarding() {
        guard canCompleteOnboarding else { return }
        isComplete = true
        // Supabase persistence (users row + user_locations + user_skills) is handled
        // in UserSessionManager.signUp, which reads selectedRole, selectedSkills, and
        // selectedCity from this state after the user provides credentials.
    }
}
