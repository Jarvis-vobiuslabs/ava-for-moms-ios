import SwiftUI

@Observable
class OnboardingData {

    // Step 1 — Name
    var name: String = ""

    // Step 2 — Family
    var hasPartner: Bool = false
    var partnerName: String = ""
    var kids: [Kid] = []

    // Step 3 — Week
    var workStatus: WorkStatus = .fullTime
    var hasSchoolPickup: Bool = false
    var schoolPickupTime: Date = Calendar.current.date(
        bySettingHour: 15, minute: 30, second: 0, of: Date()
    ) ?? Date()

    // Step 4 — Mental load
    var mentalLoadAreas: Set<MentalLoad> = []

    // MARK: - Sub-types

    struct Kid: Identifiable {
        let id = UUID()
        var name: String = ""
        var age: Int = 5
    }

    enum WorkStatus: String, CaseIterable {
        case fullTime   = "Full-time"
        case partTime   = "Part-time"
        case stayAtHome = "Stay at home"
        case freelance  = "Freelancer"
        case other      = "Other"

        var emoji: String {
            switch self {
            case .fullTime:   return "💼"
            case .partTime:   return "⏰"
            case .stayAtHome: return "🏠"
            case .freelance:  return "💻"
            case .other:      return "✨"
            }
        }
    }

    enum MentalLoad: String, CaseIterable, Hashable {
        case meals        = "Meal planning"
        case school       = "School logistics"
        case appointments = "Appointments"
        case tasks        = "Tasks & errands"
        case budget       = "Budget"
        case activities   = "Activities & sports"
        case everything   = "Just everything"

        var emoji: String {
            switch self {
            case .meals:        return "🍳"
            case .school:       return "🎒"
            case .appointments: return "🏥"
            case .tasks:        return "✅"
            case .budget:       return "💰"
            case .activities:   return "⚽️"
            case .everything:   return "😮‍💨"
            }
        }
    }

    // MARK: - Summary helpers (used on paywall)

    var familySummary: String {
        var parts: [String] = []
        if hasPartner            { parts.append("partner") }
        if kids.count == 1       { parts.append("1 kid") }
        else if kids.count > 1   { parts.append("\(kids.count) kids") }
        return parts.isEmpty ? "just you" : parts.joined(separator: " · ")
    }

    var loadSummary: String {
        let picked = MentalLoad.allCases.filter { mentalLoadAreas.contains($0) }
        if picked.isEmpty          { return "the mental load" }
        if picked.count > 2        { return "\(picked[0].rawValue.lowercased()) + \(picked.count - 1) more" }
        return picked.map { $0.rawValue.lowercased() }.joined(separator: " · ")
    }
}
