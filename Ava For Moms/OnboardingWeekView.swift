import SwiftUI

struct OnboardingWeekView: View {
    @Bindable var data: OnboardingData
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            backButton

            VStack(alignment: .leading, spacing: 14) {
                Text("What does your\nweek look like?")
                    .font(AvaTheme.font(34, weight: .heavy))
                    .foregroundStyle(AvaTheme.ink)
                    .tracking(-1)
                    .lineSpacing(2)

                Text("Ava uses this to shape your daily brief and reminders.")
                    .font(AvaTheme.font(16, weight: .medium))
                    .foregroundStyle(AvaTheme.inkMute)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 28)
            .padding(.top, 36)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    workStatusSection
                    schoolPickupSection
                }
                .padding(.horizontal, 22)
                .padding(.top, 32)
                .padding(.bottom, 20)
            }

            Button(action: onNext) {
                Text("Continue →")
                    .font(AvaTheme.font(16, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Capsule().fill(AvaTheme.blushTerracotta))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 28)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    // MARK: - Work status

    private var workStatusSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Work & career")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(OnboardingData.WorkStatus.allCases, id: \.self) { status in
                    workChip(status)
                }
            }
        }
    }

    private func workChip(_ status: OnboardingData.WorkStatus) -> some View {
        let selected = data.workStatus == status
        return Button { data.workStatus = status } label: {
            HStack(spacing: 10) {
                Text(status.emoji).font(.system(size: 18))
                Text(status.rawValue)
                    .font(AvaTheme.font(14, weight: .bold))
                    .foregroundStyle(selected ? .white : AvaTheme.ink)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selected ? AvaTheme.terracotta : AvaTheme.cream)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected ? AvaTheme.terracotta : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: selected)
    }

    // MARK: - School pickup

    private var schoolPickupSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("School run")

            VStack(spacing: 0) {
                // Toggle row
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AvaTheme.bgDeep)
                                .frame(width: 36, height: 36)
                            Text("🚗").font(.system(size: 16))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("I do school pickup")
                                .font(AvaTheme.font(15, weight: .bold))
                                .foregroundStyle(AvaTheme.ink)
                            Text("Ava will build this into your afternoon")
                                .font(AvaTheme.font(12, weight: .medium))
                                .foregroundStyle(AvaTheme.inkMute)
                        }
                    }
                    Spacer()
                    Toggle("", isOn: $data.hasSchoolPickup)
                        .labelsHidden()
                        .tint(AvaTheme.terracotta)
                }
                .padding(16)
                .background(AvaTheme.cream)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 18, bottomLeadingRadius: data.hasSchoolPickup ? 0 : 18,
                        bottomTrailingRadius: data.hasSchoolPickup ? 0 : 18, topTrailingRadius: 18
                    )
                )

                // Time picker expanding section
                if data.hasSchoolPickup {
                    HStack {
                        Text("Usual pickup time")
                            .font(AvaTheme.font(14, weight: .medium))
                            .foregroundStyle(AvaTheme.inkMute)
                        Spacer()
                        DatePicker("", selection: $data.schoolPickupTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .tint(AvaTheme.terracotta)
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
            .animation(.spring(duration: 0.3), value: data.hasSchoolPickup)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(AvaTheme.font(11, weight: .heavy))
            .foregroundStyle(AvaTheme.inkSoft)
            .tracking(0.8)
            .padding(.leading, 4)
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

#Preview {
    OnboardingWeekView(data: OnboardingData(), onNext: {}, onBack: {})
}
