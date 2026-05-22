import SwiftUI
import Supabase

struct ProfileEditView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var workStatus: WorkStatusOption = .fullTime
    @State private var hasSchoolPickup = false
    @State private var isSaving = false
    @State private var isLoading = true
    @FocusState private var nameFocused: Bool

    enum WorkStatusOption: String, CaseIterable {
        case fullTime   = "full_time"
        case partTime   = "part_time"
        case stayAtHome = "stay_at_home"
        case freelance  = "freelancer"
        case other      = "other"

        var label: String {
            switch self {
            case .fullTime:   return "Full-time"
            case .partTime:   return "Part-time"
            case .stayAtHome: return "Stay at home"
            case .freelance:  return "Freelancer"
            case .other:      return "Other"
            }
        }
        var emoji: String {
            switch self {
            case .fullTime: return "💼"; case .partTime: return "⏰"
            case .stayAtHome: return "🏠"; case .freelance: return "💻"
            case .other: return "✨"
            }
        }
    }

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(AvaTheme.font(16, weight: .semibold))
                        .foregroundStyle(AvaTheme.terracotta).buttonStyle(.plain)
                    Spacer()
                    Text("Edit Profile")
                        .font(AvaTheme.font(17, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                    Spacer()
                    Button("Save") { _Concurrency.Task { await save() } }
                        .font(AvaTheme.font(16, weight: .heavy))
                        .foregroundStyle(isSaving ? AvaTheme.inkSoft : AvaTheme.terracotta)
                        .buttonStyle(.plain).disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 24)

                if isLoading {
                    Spacer(); ProgressView().tint(AvaTheme.terracotta); Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Name
                            VStack(alignment: .leading, spacing: 8) {
                                label("YOUR NAME")
                                HStack(spacing: 12) {
                                    Image(systemName: "person")
                                        .font(.system(size: 15)).foregroundStyle(AvaTheme.inkSoft).frame(width: 20)
                                    TextField("First name", text: $name)
                                        .font(AvaTheme.font(16, weight: .semibold)).foregroundStyle(AvaTheme.ink)
                                        .textInputAutocapitalization(.words).autocorrectionDisabled()
                                        .focused($nameFocused)
                                }
                                .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))
                            }

                            // Work status
                            VStack(alignment: .leading, spacing: 8) {
                                label("WORK & CAREER")
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach(WorkStatusOption.allCases, id: \.self) { option in
                                        Button { workStatus = option } label: {
                                            HStack(spacing: 8) {
                                                Text(option.emoji)
                                                Text(option.label)
                                                    .font(AvaTheme.font(13, weight: .bold))
                                                    .foregroundStyle(workStatus == option ? .white : AvaTheme.ink)
                                                    .lineLimit(1)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 12).padding(.vertical, 13)
                                            .background(RoundedRectangle(cornerRadius: 14)
                                                .fill(workStatus == option ? AvaTheme.terracotta : AvaTheme.cream))
                                        }
                                        .buttonStyle(.plain)
                                        .animation(.easeInOut(duration: 0.15), value: workStatus)
                                    }
                                }
                            }

                            // School pickup
                            VStack(alignment: .leading, spacing: 8) {
                                label("SCHOOL RUN")
                                HStack {
                                    HStack(spacing: 10) {
                                        Text("🚗").font(.system(size: 18))
                                        Text("I do school pickup")
                                            .font(AvaTheme.font(15, weight: .bold)).foregroundStyle(AvaTheme.ink)
                                    }
                                    Spacer()
                                    Toggle("", isOn: $hasSchoolPickup).labelsHidden().tint(AvaTheme.terracotta)
                                }
                                .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(AvaTheme.cream))
                            }
                        }
                        .padding(.horizontal, 18)
                        Spacer().frame(height: 40)
                    }
                }
            }
        }
        .task { await loadProfile() }
    }

    private func label(_ text: String) -> some View {
        Text(text).font(AvaTheme.font(11, weight: .heavy))
            .foregroundStyle(AvaTheme.inkSoft).tracking(0.8)
    }

    private func loadProfile() async {
        guard let userId = auth.currentUserId else { isLoading = false; return }
        struct ProfileRow: Decodable {
            let name: String?
            let workStatus: String?
            let hasSchoolPickup: Bool?
            enum CodingKeys: String, CodingKey {
                case name; case workStatus = "work_status"; case hasSchoolPickup = "has_school_pickup"
            }
        }
        if let p = try? await supabase.from("profiles").select("name, work_status, has_school_pickup")
            .eq("id", value: userId.uuidString).single().execute().value as ProfileRow {
            name = p.name ?? auth.firstName
            workStatus = WorkStatusOption(rawValue: p.workStatus ?? "full_time") ?? .fullTime
            hasSchoolPickup = p.hasSchoolPickup ?? false
        }
        isLoading = false
    }

    private func save() async {
        isSaving = true
        guard let userId = auth.currentUserId else { isSaving = false; return }
        let update: [String: AnyJSON] = [
            "name": .string(name.trimmingCharacters(in: .whitespaces)),
            "work_status": .string(workStatus.rawValue),
            "has_school_pickup": .bool(hasSchoolPickup),
        ]
        let q = try? supabase.from("profiles").update(update, returning: .minimal).eq("id", value: userId.uuidString)
        _ = try? await q?.execute()
        auth.userName = name.trimmingCharacters(in: .whitespaces)
        isSaving = false
        dismiss()
    }
}
