import SwiftUI

struct OnboardingFamilyView: View {
    @Bindable var data: OnboardingData
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            backButton

            VStack(alignment: .leading, spacing: 14) {
                Text("Tell Ava about\nyour people.")
                    .font(AvaTheme.font(34, weight: .heavy))
                    .foregroundStyle(AvaTheme.ink)
                    .tracking(-1)
                    .lineSpacing(2)

                Text("She'll keep everyone's schedules and needs in mind.")
                    .font(AvaTheme.font(16, weight: .medium))
                    .foregroundStyle(AvaTheme.inkMute)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 28)
            .padding(.top, 36)

            ScrollView {
                VStack(spacing: 14) {
                    // Partner
                    partnerSection
                    // Kids
                    kidsSection
                }
                .padding(.horizontal, 22)
                .padding(.top, 28)
                .padding(.bottom, 20)
            }

            // Skip / Continue
            VStack(spacing: 10) {
                Button(action: onNext) {
                    Text("Continue →")
                        .font(AvaTheme.font(16, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Capsule().fill(AvaTheme.blushTerracotta))
                }
                .buttonStyle(.plain)

                Button(action: onNext) {
                    Text("Just me for now")
                        .font(AvaTheme.font(14, weight: .semibold))
                        .foregroundStyle(AvaTheme.inkMute)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    // MARK: - Partner

    private var partnerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Toggle row
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AvaTheme.bgDeep)
                            .frame(width: 36, height: 36)
                        Text("💑").font(.system(size: 16))
                    }
                    Text("Partner")
                        .font(AvaTheme.font(15, weight: .bold))
                        .foregroundStyle(AvaTheme.ink)
                }
                Spacer()
                Toggle("", isOn: $data.hasPartner)
                    .labelsHidden()
                    .tint(AvaTheme.terracotta)
            }
            .padding(16)
            .background(AvaTheme.cream)
            .clipShape(
                RoundedRectangle(cornerRadius: data.hasPartner ? 0 : 18)
                    .rect(cornerRadius: 18,
                          style: .continuous)
            )
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 18, bottomLeadingRadius: data.hasPartner ? 0 : 18,
                    bottomTrailingRadius: data.hasPartner ? 0 : 18, topTrailingRadius: 18
                )
            )

            // Expanding name field
            if data.hasPartner {
                HStack(spacing: 12) {
                    Text("Their name")
                        .font(AvaTheme.font(14, weight: .medium))
                        .foregroundStyle(AvaTheme.inkMute)
                        .frame(width: 90, alignment: .leading)
                    TextField("e.g. Dan", text: $data.partnerName)
                        .font(AvaTheme.font(15, weight: .semibold))
                        .foregroundStyle(AvaTheme.ink)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AvaTheme.bgDeep)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0, bottomLeadingRadius: 18,
                        bottomTrailingRadius: 18, topTrailingRadius: 0
                    )
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: data.hasPartner)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Kids

    private var kidsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AvaTheme.bgDeep)
                            .frame(width: 36, height: 36)
                        Text("🧒").font(.system(size: 16))
                    }
                    Text("Kids")
                        .font(AvaTheme.font(15, weight: .bold))
                        .foregroundStyle(AvaTheme.ink)
                }
                Spacer()
                Button(action: addKid) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(AvaTheme.font(13, weight: .bold))
                    .foregroundStyle(AvaTheme.terracotta)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(AvaTheme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            if !data.kids.isEmpty {
                VStack(spacing: 8) {
                    ForEach($data.kids) { $kid in
                        KidRow(kid: $kid, onRemove: { removeKid(kid) })
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(duration: 0.3), value: data.kids.count)
            }
        }
    }

    private func addKid() {
        withAnimation(.spring(duration: 0.3)) {
            data.kids.append(OnboardingData.Kid())
        }
    }

    private func removeKid(_ kid: OnboardingData.Kid) {
        withAnimation(.spring(duration: 0.3)) {
            data.kids.removeAll { $0.id == kid.id }
        }
    }

    private var backButton: some View {
        Button(action: onBack) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                Text("Back")
                    .font(AvaTheme.font(15, weight: .semibold))
            }
            .foregroundStyle(AvaTheme.inkMute)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }
}

// MARK: - Kid row

private struct KidRow: View {
    @Binding var kid: OnboardingData.Kid
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("Name", text: $kid.name)
                .font(AvaTheme.font(15, weight: .semibold))
                .foregroundStyle(AvaTheme.ink)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .frame(maxWidth: .infinity)

            // Age stepper
            HStack(spacing: 8) {
                Button { if kid.age > 0 { kid.age -= 1 } } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AvaTheme.inkSoft)
                }
                .buttonStyle(.plain)

                Text("\(kid.age)")
                    .font(AvaTheme.font(15, weight: .heavy))
                    .foregroundStyle(AvaTheme.ink)
                    .frame(width: 26, alignment: .center)

                Button { if kid.age < 18 { kid.age += 1 } } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AvaTheme.terracotta)
                }
                .buttonStyle(.plain)
            }

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AvaTheme.inkSoft)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AvaTheme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    OnboardingFamilyView(data: OnboardingData(), onNext: {}, onBack: {})
}
