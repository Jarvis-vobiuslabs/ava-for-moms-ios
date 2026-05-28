import SwiftUI
import Supabase
import StoreKit

struct AccountView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var showSignOutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var showDeleteFinal = false
    @State private var isDeleting = false
    @State private var showMemories = false
    @State private var showEditProfile = false
    @State private var showFamily = false
    @State private var showManageSubscriptions = false
    @State private var deleteError: String?

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ─────────────────────────────────────────────
                    HStack {
                        Text("Account")
                            .font(AvaTheme.font(28, weight: .heavy))
                            .foregroundStyle(AvaTheme.ink)
                            .tracking(-0.6)
                        Spacer()
                        Button { dismiss() } label: {
                            Circle().fill(AvaTheme.cream).frame(width: 36, height: 36)
                                .overlay(Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AvaTheme.inkMute))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24).padding(.top, 60).padding(.bottom, 24)

                    // ── Profile ────────────────────────────────────────────
                    sectionHeader("PROFILE")
                    settingsCard {
                        row(icon: "person.circle", title: "Edit Profile") { showEditProfile = true }
                        Divider().padding(.leading, 54).tint(AvaTheme.line)
                        row(icon: "figure.2.and.child.holdinghands", title: "Family Members") { showFamily = true }
                    }

                    // ── Ava ───────────────────────────────────────────────
                    sectionHeader("AVA")
                    settingsCard {
                        row(icon: "brain", title: "What Ava remembers") { showMemories = true }
                    }

                    // ── Legal ──────────────────────────────────────────────
                    sectionHeader("LEGAL")
                    settingsCard {
                        Link(destination: URL(string: "https://avaformoms.com/terms")!) {
                            rowLabel(icon: "doc.text", title: "Terms of Service")
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 54).tint(AvaTheme.line)
                        Link(destination: URL(string: "https://avaformoms.com/privacy")!) {
                            rowLabel(icon: "lock.shield", title: "Privacy Policy")
                        }
                        .buttonStyle(.plain)
                    }

                    // ── Support ────────────────────────────────────────────
                    sectionHeader("SUPPORT")
                    settingsCard {
                        Link(destination: URL(string: "mailto:labs@vobius.com")!) {
                            rowLabel(icon: "envelope", title: "Contact Support")
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 54).tint(AvaTheme.line)
                        Link(destination: URL(string: "https://avaformoms.com/faq")!) {
                            rowLabel(icon: "questionmark.circle", title: "FAQ")
                        }
                        .buttonStyle(.plain)
                    }

                    // ── Subscription ───────────────────────────────────────
                    sectionHeader("SUBSCRIPTION")
                    settingsCard {
                        row(icon: "creditcard", title: "Manage Subscription") {
                            showManageSubscriptions = true
                        }
                    }

                    // ── Account ────────────────────────────────────────────
                    sectionHeader("ACCOUNT")
                    settingsCard {
                        row(icon: "rectangle.portrait.and.arrow.right",
                            title: "Sign Out",
                            titleColor: AvaTheme.terracotta) {
                            showSignOutConfirm = true
                        }
                    }

                    // ── Danger zone ────────────────────────────────────────
                    sectionHeader("DANGER ZONE")
                    VStack(alignment: .leading, spacing: 8) {
                        Button { showDeleteConfirm = true } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: "FDEDED"))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "trash")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color(hex: "C0392B"))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Delete Account & Data")
                                        .font(AvaTheme.font(15, weight: .bold))
                                        .foregroundStyle(Color(hex: "C0392B"))
                                    Text("Permanently removes your account and all data")
                                        .font(AvaTheme.font(12, weight: .medium))
                                        .foregroundStyle(AvaTheme.inkMute)
                                }
                                Spacer()
                            }
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 18).fill(AvaTheme.cream))
                        }
                        .buttonStyle(.plain)

                        Text("This cannot be undone. All your conversations, memories, tasks, and grocery lists will be permanently deleted.")
                            .font(AvaTheme.font(12, weight: .medium))
                            .foregroundStyle(AvaTheme.inkSoft)
                            .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 18)

                    if let err = deleteError {
                        Text(err)
                            .font(AvaTheme.font(13, weight: .medium))
                            .foregroundStyle(Color(hex: "C0392B"))
                            .padding(.horizontal, 24).padding(.top, 8)
                    }

                    Spacer().frame(height: 60)
                }
            }
        }
        // Sign out confirmation
        .confirmationDialog("Sign out of Ava?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                _Concurrency.Task { await auth.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        }
        // Delete step 1
        .confirmationDialog("Delete your account?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Yes, delete everything", role: .destructive) { showDeleteFinal = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your profile, all conversations, memories, tasks and grocery lists.")
        }
        // Delete step 2 — second confirmation
        .alert("Are you absolutely sure?", isPresented: $showDeleteFinal) {
            Button("Delete My Account", role: .destructive) {
                _Concurrency.Task { await deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
        .sheet(isPresented: $showMemories)    { MemoriesView().environment(auth) }
        .sheet(isPresented: $showEditProfile) { ProfileEditView().environment(auth) }
        .sheet(isPresented: $showFamily)      { FamilyManagementView().environment(auth) }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .overlay {
            if isDeleting {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView().tint(.white).scaleEffect(1.3)
                        Text("Deleting your account…")
                            .font(AvaTheme.font(15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    // MARK: - Delete account

    private func deleteAccount() async {
        guard let userId = auth.currentUserId else { return }
        isDeleting = true
        deleteError = nil

        do {
            let session = try await supabase.auth.session
            var request = URLRequest(
                url: URL(string: "https://syhzfjrvbrqrsesxubtx.supabase.co/functions/v1/delete-account")!
            )
            request.httpMethod = "POST"
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN5aHpmanJ2YnJxcnNlc3h1YnR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwOTEwOTYsImV4cCI6MjA5MzY2NzA5Nn0.6vXXbQkc0R7GdO3F8lES6bqnoxC5rgaBzaYz3R8t1Dg",
                forHTTPHeaderField: "apikey"
            )
            request.httpBody = try JSONSerialization.data(withJSONObject: ["userId": userId.uuidString])

            let (_, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Deletion failed. Contact labs@vobius.com"])
            }

            await auth.signOut()
        } catch {
            deleteError = error.localizedDescription
            isDeleting = false
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(AvaTheme.font(11, weight: .heavy))
            .foregroundStyle(AvaTheme.inkSoft)
            .tracking(0.8)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .background(RoundedRectangle(cornerRadius: 18).fill(AvaTheme.cream))
            .padding(.horizontal, 18)
    }

    private func row(icon: String, title: String, titleColor: Color = AvaTheme.ink, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            rowLabel(icon: icon, title: title, titleColor: titleColor)
        }
        .buttonStyle(.plain)
    }

    private func rowLabel(icon: String, title: String, titleColor: Color = AvaTheme.ink) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(AvaTheme.bgDeep).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 15, weight: .medium)).foregroundStyle(AvaTheme.inkMute)
            }
            Text(title).font(AvaTheme.font(15, weight: .bold)).foregroundStyle(titleColor)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(AvaTheme.inkSoft)
        }
        .padding(16)
    }
}

#Preview {
    AccountView().environment(AuthManager())
}
