//
//  AboutUsView.swift
//  DriveBuddy
//
//  Created by Timothy on 20/11/25.
//

import SwiftUI

struct AboutUsView: View {
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		ZStack {
			// MARK: - Background
			Color.black.opacity(0.95)
				.ignoresSafeArea()
			
			// MARK: - Animated Background Elements
			FlowingLinesView()
				.ignoresSafeArea()
				.opacity(0.3)
			
			ScrollView(showsIndicators: false) {
				VStack(spacing: 30) {
					// MARK: - Header
					VStack(spacing: 8) {
						HStack (alignment: .center) {
														
							Text("About Us")
								.font(.title2)
								.fontWeight(.bold)
								.foregroundColor(.white)
						}
						.padding(.horizontal)
						
						// App Logo
						VStack(spacing: 10) {
							Text("DriveBuddy")
								.font(.system(size: 32, weight: .bold, design: .rounded))
								.foregroundColor(.white)
								.shadow(color: .blue, radius: 10)
							
							Text("Your Vehicle's Best Friend")
								.font(.title3)
								.foregroundColor(.cyan)
								.fontWeight(.medium)
						}
					}
					
					// MARK: - Mission Section
					AboutCard(
						icon: "target",
						title: "Our Mission",
						content: "To revolutionize vehicle ownership by providing smart, intuitive tools that keep your car healthy, your expenses predictable, and your driving experience worry-free.",
						gradientColors: [.blue, .cyan]
					)
					
					// MARK: - Vision Section
					AboutCard(
						icon: "eye.fill",
						title: "Our Vision",
						content: "To become the most trusted automotive companion app worldwide, empowering every vehicle owner with AI-driven insights and proactive maintenance solutions.",
						gradientColors: [.purple, .blue]
					)
					
					// MARK: - Features Highlights
					VStack(alignment: .leading, spacing: 20) {
						Text("Why Choose DriveBuddy?")
							.font(.title2)
							.fontWeight(.bold)
							.foregroundColor(.white)
							.padding(.horizontal)
						
						LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
							FeatureItem(
								icon: "bell.badge.fill",
								title: "Smart Reminders",
								description: "Never miss service dates"
							)
							
							FeatureItem(
								icon: "map.fill",
								title: "Workshop Finder",
								description: "Best mechanics nearby"
							)
							
							FeatureItem(
								icon: "chart.line.uptrend.xyaxis",
								title: "Tax Tracking",
								description: "Monitor vehicle's tax"
							)
							
							FeatureItem(
								icon: "doc.text.fill",
								title: "Digital Records",
								description: "All history in one place"
							)
						}
						.padding(.horizontal)
					}
					
					// MARK: - Team Section
					VStack(alignment: .leading, spacing: 20) {
						Text("Meet The Team")
							.font(.title2)
							.fontWeight(.bold)
							.foregroundColor(.white)
							.padding(.horizontal)
						
						ScrollView(.horizontal, showsIndicators: false) {
							HStack(spacing: 15) {
								TeamMemberCard(
									name: "Amanda",
									nim: "0706022310051",
									image: "person.crop.circle.fill",
									color: .blue
								)
								
								TeamMemberCard(
									name: "Anne",
									nim: "0706022310043",
									image: "person.crop.circle.fill",
									color: .green
								)
								
								TeamMemberCard(
									name: "Dwinda",
									nim: "0706022310047",
									image: "person.crop.circle.fill",
									color: .orange
								)
								
								TeamMemberCard(
									name: "Howie",
									nim: "0706022310040",
									image: "person.crop.circle.fill",
									color: .purple
								)
								
								TeamMemberCard(
									name: "Jacq",
									nim: "0706022310042",
									image: "person.crop.circle.fill",
									color: .purple
								)
							}
							.padding(.horizontal)
						}
						.fixedSize(horizontal: false, vertical: true) // Tambahkan ini
					}
					
					// MARK: - App Info
					VStack(spacing: 15) {
						InfoRow(icon: "app.badge.fill", text: "Version 1.0.0")
						InfoRow(icon: "hammer.fill", text: "Build 2025.12")
						InfoRow(icon: "calendar", text: "Launched December 2025")
					}
					.padding()
					.background(
						RoundedRectangle(cornerRadius: 15)
							.fill(Color.blue.opacity(0.1))
							.overlay(
								RoundedRectangle(cornerRadius: 15)
									.stroke(Color.blue.opacity(0.3), lineWidth: 1)
							)
					)
					.padding(.horizontal)
					
					// MARK: - Contact Section (Stylish Version)
					VStack(spacing: 15) {
						Text("Get In Touch")
							.font(.title2)
							.fontWeight(.bold)
							.foregroundColor(.white)
						
						Text("We'd love to hear from you! Send us your feedback, suggestions, or just say hello.")
							.font(.body)
							.foregroundColor(.white.opacity(0.8))
							.multilineTextAlignment(.center)
							.padding(.horizontal)
						
						// Contact List dengan glow effect
						VStack(spacing: 0) {
							ContactListRow(
								icon: "envelope.fill",
								title: "Email",
								subtitle: "drivebuddy@gmail.com",
								iconColor: .blue,
								action: {
									if let url = URL(string: "mailto:drivebuddy@gmail.com") {
										UIApplication.shared.open(url)
									}
								}
							)
							
							Divider()
								.background(Color.white.opacity(0.2))
								.padding(.leading, 50)
							
							ContactListRow(
								icon: "phone.fill",
								title: "Phone Number",
								subtitle: "0812345678",
								iconColor: .green,
								action: {
									let phoneNumber = "0812345678"
									if let url = URL(string: "tel://\(phoneNumber)") {
										UIApplication.shared.open(url)
									}
								}
							)
						}
						.background(
							RoundedRectangle(cornerRadius: 12)
								.fill(Color.white.opacity(0.05))
								.overlay(
									RoundedRectangle(cornerRadius: 12)
										.stroke(
											LinearGradient(
												colors: [.cyan, .blue],
												startPoint: .leading,
												endPoint: .trailing
											).opacity(0.4),
											lineWidth: 1
										)
								)
								.shadow(color: .blue.opacity(0.2), radius: 5, x: 0, y: 2)
						)
						.padding(.horizontal)
					}
					.padding()
					.background(
						RoundedRectangle(cornerRadius: 15)
							.fill(
								LinearGradient(
									colors: [.cyan.opacity(0.08), .blue.opacity(0.05)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.overlay(
								RoundedRectangle(cornerRadius: 15)
									.stroke(
										LinearGradient(
											colors: [.cyan.opacity(0.3), .blue.opacity(0.2)],
											startPoint: .leading,
											endPoint: .trailing
										),
										lineWidth: 1
									)
							)
					)
					.padding(.horizontal)
					// MARK: - Footer
					VStack(spacing: 10) {
						Text("Drive Safe, Drive Smart")
							.font(.headline)
							.foregroundColor(.cyan)
						
						Text("© 2025 DriveBuddy. All rights reserved.")
							.font(.caption)
							.foregroundColor(.white.opacity(0.6))
					}
					.padding(.bottom, 30)
				}
			}
		}
		.navigationBarHidden(true)
	}
}

// MARK: - About Card Component
struct AboutCard: View {
	let icon: String
	let title: String
	let content: String
	let gradientColors: [Color]
	
	var body: some View {
		VStack(spacing: 15) {
			HStack(spacing: 12) {
				Image(systemName: icon)
					.font(.title2)
					.foregroundColor(.white)
					.frame(width: 40, height: 40)
					.background(
						LinearGradient(
							colors: gradientColors,
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.clipShape(Circle())
				
				Text(title)
					.font(.title3)
					.fontWeight(.bold)
					.foregroundColor(.white)
				
				Spacer()
			}
			
			Text(content)
				.font(.body)
				.foregroundColor(.white.opacity(0.8))
				.lineSpacing(4)
				.multilineTextAlignment(.leading)
		}
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 15)
				.fill(Color.white.opacity(0.05))
				.overlay(
					RoundedRectangle(cornerRadius: 15)
						.stroke(
							LinearGradient(
								colors: gradientColors,
								startPoint: .leading,
								endPoint: .trailing
							).opacity(0.3),
							lineWidth: 1
						)
				)
		)
		.padding(.horizontal)
	}
}

// MARK: - Feature Item Component
struct FeatureItem: View {
	let icon: String
	let title: String
	let description: String
	
	var body: some View {
		VStack(spacing: 8) {
			Image(systemName: icon)
				.font(.title2)
				.foregroundColor(.cyan)
				.frame(width: 50, height: 50)
				.background(Color.cyan.opacity(0.1))
				.clipShape(Circle())
			
			Text(title)
				.font(.system(size: 14, weight: .semibold))
				.foregroundColor(.white)
				.multilineTextAlignment(.center)
			
			Text(description)
				.font(.system(size: 12))
				.foregroundColor(.white.opacity(0.7))
				.multilineTextAlignment(.center)
				.lineLimit(2)
		}
		.padding()
		.frame(maxWidth: .infinity)
		.background(
			RoundedRectangle(cornerRadius: 12)
				.fill(Color.white.opacity(0.05))
		)
	}
}

// MARK: - Contact List Row Component (With Custom Icon Color)
struct ContactListRow: View {
	let icon: String
	let title: String
	let subtitle: String
	var iconColor: Color = .cyan
	let action: () -> Void
	
	var body: some View {
		Button(action: action) {
			HStack(spacing: 15) {
				// Icon dengan background
				Image(systemName: icon)
					.font(.system(size: 16))
					.foregroundColor(.white)
					.frame(width: 36, height: 36)
					.background(
						Circle()
							.fill(
								LinearGradient(
									colors: [iconColor, iconColor.opacity(0.7)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
					)
				
				// Text Content
				VStack(alignment: .leading, spacing: 2) {
					Text(title)
						.font(.system(size: 16, weight: .semibold))
						.foregroundColor(.white)
					
					Text(subtitle)
						.font(.system(size: 14))
						.foregroundColor(.white.opacity(0.7))
				}
				
				Spacer()			}
			.padding(.horizontal, 16)
			.padding(.vertical, 12)
		}
	}
}
// MARK: - Team Member Card Component
struct TeamMemberCard: View {
	let name: String
	let nim: String
	let image: String
	let color: Color
	
	var body: some View {
		VStack(spacing: 10) {
			Image(systemName: image)
				.font(.system(size: 40))
				.foregroundColor(.white)
				.frame(width: 80, height: 80)
				.background(
					LinearGradient(
						colors: [color, color.opacity(0.7)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
				.clipShape(Circle())
			
			VStack(spacing: 4) {
				Text(name)
					.font(.system(size: 14, weight: .semibold))
					.foregroundColor(.white)
					.multilineTextAlignment(.center)
				
				Text(nim)
					.font(.system(size: 12))
					.foregroundColor(.white.opacity(0.7))
					.multilineTextAlignment(.center)
			}
		}
		.padding()
		.frame(width: 140)
		.background(
			RoundedRectangle(cornerRadius: 15)
				.fill(Color.white.opacity(0.05))
				.overlay(
					RoundedRectangle(cornerRadius: 15)
						.stroke(color.opacity(0.3), lineWidth: 1)
				)
		)
	}
}

// MARK: - Info Row Component
struct InfoRow: View {
	let icon: String
	let text: String
	
	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: icon)
				.font(.system(size: 14))
				.foregroundColor(.cyan)
				.frame(width: 20)
			
			Text(text)
				.font(.system(size: 14))
				.foregroundColor(.white.opacity(0.8))
			
			Spacer()
		}
	}
}

// MARK: - Contact Button Component
struct ContactButton: View {
	let icon: String
	let label: String
	let action: () -> Void
	
	var body: some View {
		Button(action: action) {
			VStack(spacing: 8) {
				Image(systemName: icon)
					.font(.title3)
					.foregroundColor(.cyan)
				
				Text(label)
					.font(.system(size: 12, weight: .medium))
					.foregroundColor(.white.opacity(0.8))
			}
			.padding()
			.frame(width: 80)
			.background(
				RoundedRectangle(cornerRadius: 12)
					.fill(Color.white.opacity(0.05))
					.overlay(
						RoundedRectangle(cornerRadius: 12)
							.stroke(Color.cyan.opacity(0.3), lineWidth: 1)
					)
			)
		}
	}
}

// MARK: - Preview
#Preview {
	AboutUsView()
}

#Preview("Dark Mode") {
	AboutUsView()
		.preferredColorScheme(.dark)
}

#Preview("Light Mode") {
	AboutUsView()
		.preferredColorScheme(.light)
}
