import SwiftUI

struct LegalView: View {
    enum LegalType { case terms, privacy }
    let type: LegalType
    @Environment(\.dismiss) private var dismiss

    var title: String { type == .terms ? "Terms of Service" : "Privacy Policy" }

    var body: some View {
        ZStack {
            AvaTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(title)
                        .font(AvaTheme.font(22, weight: .heavy))
                        .foregroundStyle(AvaTheme.ink)
                    Spacer()
                    Button { dismiss() } label: {
                        Circle().fill(AvaTheme.cream).frame(width: 36, height: 36)
                            .overlay(Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(AvaTheme.inkMute))
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24).padding(.top, 60).padding(.bottom, 20)

                ScrollView {
                    Text(type == .terms ? termsText : privacyText)
                        .font(AvaTheme.font(14, weight: .regular))
                        .foregroundStyle(AvaTheme.inkMute)
                        .lineSpacing(5)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 60)
                }
            }
        }
    }
}

// MARK: - Terms of Service

private let termsText = """
Last updated: May 2026

These Terms of Service ("Terms") govern your use of the Ava for Moms mobile application ("App") operated by Vobius Labs Inc. ("we," "us," or "our"). By using the App, you agree to these Terms.

1. THE SERVICE
Ava for Moms provides an AI-powered personal assistant designed to help with daily organisation, family scheduling, and mental load management. The App uses artificial intelligence to provide personalised suggestions and responses.

2. SUBSCRIPTIONS AND BILLING
The App is available on a subscription basis. Subscriptions are billed through Apple's App Store and are subject to Apple's terms of service. Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current billing period. You can manage and cancel subscriptions in your Apple ID Account Settings. We do not offer refunds for partial subscription periods, except where required by applicable law.

Subscription tiers:
• Ava Standard: $9.99/month or $74.99/year
• Ava Pro: $29.99/month or $224.99/year

3. ACCOUNT
You are responsible for maintaining the confidentiality of your account. You must be at least 13 years old to use the App. You agree to provide accurate information and keep it updated.

4. AI DISCLAIMER
Ava is an AI assistant and is not a substitute for professional medical, legal, financial, or other professional advice. Information provided by Ava is for general informational purposes only. We make no warranties about the accuracy or completeness of AI-generated content. Always consult qualified professionals for important decisions.

5. ACCEPTABLE USE
You agree not to misuse the App, including attempting to reverse engineer it, use it for illegal purposes, or violate any applicable laws. We reserve the right to terminate accounts that violate these Terms.

6. INTELLECTUAL PROPERTY
The App and its content are owned by Vobius Labs Inc. and protected by applicable intellectual property laws. You retain ownership of the personal data you input into the App.

7. LIMITATION OF LIABILITY
To the maximum extent permitted by law, Vobius Labs Inc. shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the App.

8. CHANGES
We may update these Terms from time to time. Continued use of the App after changes constitutes acceptance of the new Terms. We will notify you of material changes through the App or by email.

9. GOVERNING LAW
These Terms are governed by the laws of the State of Delaware, United States, without regard to conflict of law provisions.

10. CONTACT
Questions about these Terms? Contact us at legal@avaformoms.com
"""

// MARK: - Privacy Policy

private let privacyText = """
Last updated: May 2026

Vobius Labs Inc. ("we," "us," or "our") operates the Ava for Moms app. This Privacy Policy explains how we collect, use, and protect your information.

1. INFORMATION WE COLLECT

Information you provide:
• Account information (email address, name)
• Family and household information you share with Ava
• Messages and conversations with Ava
• Tasks, calendar events, and grocery lists
• App preferences and settings

Information collected automatically:
• Device type and iOS version
• App usage patterns and feature interactions
• Crash reports and performance data

2. HOW WE USE YOUR INFORMATION
We use your information to:
• Provide and improve the Ava assistant service
• Personalise Ava's responses based on your family context
• Send notifications and reminders you request
• Process subscription payments (through Apple)
• Respond to support requests
• Ensure app security and prevent fraud

3. ARTIFICIAL INTELLIGENCE
Your conversations with Ava are processed by Anthropic's Claude AI. Anthropic processes your messages solely to generate responses and does not use your data to train AI models under our enterprise agreement. We store your conversation history in encrypted form to provide continuity.

4. DATA STORAGE AND SECURITY
Your data is stored using Supabase's infrastructure with encryption at rest and in transit. We implement industry-standard security measures. However, no method of electronic storage is 100% secure.

5. SHARING YOUR INFORMATION
We do not sell your personal information. We may share data with:
• Service providers: Supabase (database), Anthropic (AI), Apple (payments), Resend (email)
• Legal requirements: If required by law or to protect rights and safety
• Business transfers: In connection with a merger or acquisition (with notice to you)

6. DATA RETENTION
We retain your data for as long as your account is active. You can request deletion of your account and all associated data at any time within the App (Account → Delete Account). We will process deletion within 30 days.

7. YOUR RIGHTS
Depending on your location, you may have rights to:
• Access the personal data we hold about you
• Correct inaccurate data
• Delete your data
• Object to or restrict certain processing
• Data portability
• Withdraw consent

To exercise these rights, contact us at privacy@avaformoms.com or use the in-app account deletion feature.

8. CHILDREN'S PRIVACY
The App is not directed at children under 13. We do not knowingly collect personal information from children under 13.

9. CALIFORNIA RESIDENTS
Under the California Consumer Privacy Act (CCPA), California residents have additional rights regarding their personal information. We do not sell personal information. To exercise CCPA rights, contact privacy@avaformoms.com.

10. CHANGES TO THIS POLICY
We may update this Privacy Policy periodically. We will notify you of material changes through the App or by email. Continued use after changes constitutes acceptance.

11. CONTACT
Privacy questions or requests: privacy@avaformoms.com
Vobius Labs Inc., Delaware, United States
"""
