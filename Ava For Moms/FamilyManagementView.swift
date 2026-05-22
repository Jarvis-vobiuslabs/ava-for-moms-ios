import SwiftUI
import Supabase

struct FamilyManagementView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var partner: PartnerEntry = .init()
    @State private var kids: [KidEntry] = []
    @State private var isLoading = true
    @State private var isSaving = false

    struct PartnerEntry {
        var exists = false
        var id: UUID? = nil
        var name = ""
    }
    struct KidEntry: Identifiable {
        var id: UUID = UUID()
        var dbId: UUID? = nil       // nil = new, not yet saved
        var name = ""
        var age = 5
        var isNew = true
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
                    Text("Family")
                        .font(AvaTheme.font(17, weight: .heavy)).foregroundStyle(AvaTheme.ink)
                    Spacer()
                    Button("Save") { _Concurrency.Task { await save() } }
                        .font(AvaTheme.font(16, weight: .heavy))
                        .foregroundStyle(isSaving ? AvaTheme.inkSoft : AvaTheme.terracotta)
                        .buttonStyle(.plain).disabled(isSaving)
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 24)

                if isLoading {
                    Spacer(); ProgressView().tint(AvaTheme.terracotta); Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {

                            // ── Partner ────────────────────────────────────
                            sectionLabel("PARTNER")
                            VStack(spacing: 0) {
                                HStack {
                                    HStack(spacing: 10) {
                                        Text("💑").font(.system(size: 18))
                                        Text("Partner")
                                            .font(AvaTheme.font(15, weight: .bold)).foregroundStyle(AvaTheme.ink)
                                    }
                                    Spacer()
                                    Toggle("", isOn: $partner.exists).labelsHidden().tint(AvaTheme.terracotta)
                                }
                                .padding(16)
                                .background(AvaTheme.cream)
                                .clipShape(UnevenRoundedRectangle(
                                    topLeadingRadius: 18, bottomLeadingRadius: partner.exists ? 0 : 18,
                                    bottomTrailingRadius: partner.exists ? 0 : 18, topTrailingRadius: 18))

                                if partner.exists {
                                    HStack(spacing: 12) {
                                        Text("Name").font(AvaTheme.font(14, weight: .medium))
                                            .foregroundStyle(AvaTheme.inkMute).frame(width: 50, alignment: .leading)
                                        TextField("e.g. Dan", text: $partner.name)
                                            .font(AvaTheme.font(15, weight: .semibold)).foregroundStyle(AvaTheme.ink)
                                            .textInputAutocapitalization(.words).autocorrectionDisabled()
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 14)
                                    .background(AvaTheme.bgDeep)
                                    .clipShape(UnevenRoundedRectangle(
                                        topLeadingRadius: 0, bottomLeadingRadius: 18,
                                        bottomTrailingRadius: 18, topTrailingRadius: 0))
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                            .animation(.spring(duration: 0.3), value: partner.exists)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .padding(.horizontal, 18)

                            // ── Kids ───────────────────────────────────────
                            HStack {
                                sectionLabel("KIDS")
                                Spacer()
                                Button { withAnimation(.spring(duration: 0.3)) { kids.append(.init()) } } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add child")
                                    }
                                    .font(AvaTheme.font(13, weight: .bold))
                                    .foregroundStyle(AvaTheme.terracotta)
                                }
                                .buttonStyle(.plain).padding(.trailing, 18)
                            }

                            if kids.isEmpty {
                                Text("No children added yet.")
                                    .font(AvaTheme.font(14, weight: .medium)).foregroundStyle(AvaTheme.inkSoft)
                                    .frame(maxWidth: .infinity).padding(.vertical, 20)
                                    .background(RoundedRectangle(cornerRadius: 16).fill(AvaTheme.cream))
                                    .padding(.horizontal, 18)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach($kids) { $kid in
                                        kidRow(kid: $kid)
                                    }
                                }
                                .padding(.horizontal, 18)
                            }
                        }
                        Spacer().frame(height: 60)
                    }
                }
            }
        }
        .task { await load() }
    }

    private func kidRow(kid: Binding<KidEntry>) -> some View {
        HStack(spacing: 12) {
            TextField("Name", text: kid.name)
                .font(AvaTheme.font(15, weight: .semibold)).foregroundStyle(AvaTheme.ink)
                .textInputAutocapitalization(.words).autocorrectionDisabled()

            HStack(spacing: 8) {
                Button { if kid.age.wrappedValue > 0 { kid.age.wrappedValue -= 1 } } label: {
                    Image(systemName: "minus.circle.fill").font(.system(size: 20)).foregroundStyle(AvaTheme.inkSoft)
                }.buttonStyle(.plain)
                Text("\(kid.age.wrappedValue)")
                    .font(AvaTheme.font(15, weight: .heavy)).foregroundStyle(AvaTheme.ink).frame(width: 24, alignment: .center)
                Button { if kid.age.wrappedValue < 18 { kid.age.wrappedValue += 1 } } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 20)).foregroundStyle(AvaTheme.terracotta)
                }.buttonStyle(.plain)
            }

            Button { withAnimation { kids.removeAll { $0.id == kid.id } } } label: {
                Image(systemName: "xmark.circle.fill").font(.system(size: 18)).foregroundStyle(AvaTheme.inkSoft)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(AvaTheme.cream))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(AvaTheme.font(11, weight: .heavy))
            .foregroundStyle(AvaTheme.inkSoft).tracking(0.8).frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
    }

    // MARK: - Load

    private func load() async {
        guard let userId = auth.currentUserId else { isLoading = false; return }
        struct MemberRow: Decodable {
            let id: UUID; let name: String; let relationship: String; let age: Int?
        }
        if let rows = try? await supabase.from("family_members")
            .select("id, name, relationship, age")
            .eq("user_id", value: userId.uuidString)
            .execute().value as [MemberRow] {
            if let p = rows.first(where: { $0.relationship == "partner" }) {
                partner = .init(exists: true, id: p.id, name: p.name)
            }
            kids = rows.filter { $0.relationship == "child" }.map {
                KidEntry(id: UUID(), dbId: $0.id, name: $0.name, age: $0.age ?? 5, isNew: false)
            }
        }
        isLoading = false
    }

    // MARK: - Save

    private func save() async {
        isSaving = true
        guard let userId = auth.currentUserId else { isSaving = false; return }

        // Partner
        if partner.exists && !partner.name.trimmingCharacters(in: .whitespaces).isEmpty {
            if let dbId = partner.id {
                let q = try? supabase.from("family_members")
                    .update(["name": AnyJSON.string(partner.name)], returning: .minimal)
                    .eq("id", value: dbId.uuidString)
                _ = try? await q?.execute()
            } else {
                let row: [String: AnyJSON] = [
                    "user_id": .string(userId.uuidString), "name": .string(partner.name),
                    "relationship": .string("partner"), "color_hex": .string("#B6A092"),
                ]
                _ = try? await (try? supabase.from("family_members").insert(row, returning: .minimal))?.execute()
            }
        } else if !partner.exists, let dbId = partner.id {
            _ = try? await supabase.from("family_members").delete(returning: .minimal)
                .eq("id", value: dbId.uuidString).execute()
        }

        // Kids — save all
        for kid in kids where !kid.name.trimmingCharacters(in: .whitespaces).isEmpty {
            if let dbId = kid.dbId {
                let q = try? supabase.from("family_members")
                    .update(["name": AnyJSON.string(kid.name), "age": AnyJSON.integer(kid.age)], returning: .minimal)
                    .eq("id", value: dbId.uuidString)
                _ = try? await q?.execute()
            } else {
                let row: [String: AnyJSON] = [
                    "user_id": .string(userId.uuidString), "name": .string(kid.name),
                    "relationship": .string("child"), "age": .integer(kid.age),
                    "color_hex": .string("#A5C09A"),
                ]
                _ = try? await (try? supabase.from("family_members").insert(row, returning: .minimal))?.execute()
            }
        }

        isSaving = false
        dismiss()
    }
}

#Preview {
    FamilyManagementView().environment(AuthManager())
}
