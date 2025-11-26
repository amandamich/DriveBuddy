import SwiftUI

struct PrivacyPolicyView: View {
	var body: some View {
		ZStack {
			// MARK: - Background
			Color.black.opacity(0.95).ignoresSafeArea()

			ScrollView {
				VStack(spacing: 24) {
					
					// MARK: - Header
					VStack(spacing: 8) {

						Text("Privacy Policy")
							.font(.system(size: 34, weight: .bold, design: .rounded))
							.foregroundColor(.white)
							.shadow(color: .blue, radius: 10)
//							.font(.system(size: 28, weight: .bold, design: .rounded))
//							.foregroundColor(.white)
//							.padding(.top, 10)

						Text("Last updated: November 5, 2025")
							.font(.subheadline)
							.foregroundColor(.gray)
					}
					.padding(.horizontal)

					// MARK: - Policy Sections
					VStack(spacing: 20) {
						PolicyCard(
							title: "1. Information We Collect",
							content: """
							We collect the following data to provide our services:
							• Personal Information: your email and password (securely stored).
							• Device Information: model, OS, and usage data.
							• Vehicle Data: make, model, license plate, and mileage.
							"""
						)

						PolicyCard(
							title: "2. How We Use Your Information",
							content: """
							• Maintain and improve app functionality.
							• Manage login and reminders.
							• Send notifications and service updates.
							• Ensure compliance with applicable laws.
							"""
						)

						PolicyCard(
							title: "3. Data Storage & Security",
							content: """
							We use encryption and strict access controls to protect your data.
							Passwords are securely hashed and never stored in plain text.
							"""
						)

						PolicyCard(
							title: "4. Data Sharing",
							content: """
							We only share data when necessary:
							• With trusted service providers (under confidentiality).
							• When required by law or legal process.
							"""
						)

						PolicyCard(
							title: "5. Your Rights",
							content: """
							You can request access, correction, or deletion of your data anytime.
							Contact us at: support@drivebuddy.app
							"""
						)

						PolicyCard(
							title: "6. Updates to This Policy",
							content: """
							We may update this Privacy Policy from time to time.
							Continued use of DriveBuddy means you accept the new terms.
							"""
						)
					}
					.padding(.horizontal)
					.padding(.bottom, 60)
					
				}
			}
		}
	}
}

struct PolicyCard: View {
	var title: String
	var content: String

	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text(title)
				.font(.headline)
				.foregroundColor(.cyan)

			Text(content)
				.font(.body)
				.foregroundColor(.white.opacity(0.9))
				.lineSpacing(4)
				.multilineTextAlignment(.leading)
		}
		.padding(.vertical, 18) // 🔧 padding seragam
		.padding(.horizontal, 14)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color.black.opacity(0.45))
				.overlay(
					RoundedRectangle(cornerRadius: 16)
						.stroke(Color.cyan.opacity(0.5), lineWidth: 1)
				)
				.shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 2)
		)
		.frame(minHeight: 140) // 🔧 tinggi minimum biar proporsional
		.padding(.horizontal, 2)
	}
}


#Preview {
	PrivacyPolicyView()
}
