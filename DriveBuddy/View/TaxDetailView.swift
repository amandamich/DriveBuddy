//
//  TaxDetailView.swift
//  DriveBuddy
//
//  Created by Timothy on 26/11/25.
//

import SwiftUI

struct TaxDetailView: View {
	let tax: TaxModel
	@StateObject private var taxManager = TaxHistoryManager.shared
	@Environment(\.dismiss) var dismiss
	@State private var showDeleteAlert = false
	
	var body: some View {
		ZStack {
			Color("BackgroundPrimary")
				.ignoresSafeArea()
			
			ScrollView(showsIndicators: false) {
				VStack(spacing: 24) {
					// Header Card with Status
					VStack(spacing: 16) {
						// Vehicle Icon
						ZStack {
							Circle()
								.fill(statusColor.opacity(0.2))
								.frame(width: 100, height: 100)
							
							Image(systemName: "car.fill")
								.font(.system(size: 44))
//								.foregroundColor(statusColor)
						}
						
						// Plate Number
						Text(tax.vehiclePlate)
							.font(.system(size: 32, weight: .bold))
							.foregroundColor(Color("TextPrimary"))
						
						Text(tax.vehicleName)
							.font(.system(size: 18))
							.foregroundColor(.gray)
						
						// Status Badge Large
						HStack(spacing: 12) {
							StatusBadge(status: tax.status)
							
							if tax.status == .expiringSoon {
								Text("\(tax.daysUntilExpiry) days left")
									.font(.system(size: 14, weight: .semibold))
									.foregroundColor(.orange)
							} else if tax.status == .expired {
								Text("Expired \(abs(tax.daysUntilExpiry)) days ago")
									.font(.system(size: 14, weight: .semibold))
									.foregroundColor(.red)
							}
						}
					}
					.padding(.top, 20)
					
					// Tax Amount Card
					VStack(spacing: 12) {
						Text("Tax Amount")
							.font(.system(size: 14))
							.foregroundColor(.gray)
						
						Text(tax.formattedAmount)
							.font(.system(size: 36, weight: .bold))
							.foregroundColor(Color("AccentNeon"))
					}
					.frame(maxWidth: .infinity)
					.padding()
					.background(
						RoundedRectangle(cornerRadius: 15)
							.fill(Color("AccentNeon").opacity(0.1))
					)
					
					// Details Section
					VStack(alignment: .leading, spacing: 16) {
						Text("Details")
							.font(.system(size: 20, weight: .bold))
							.foregroundColor(Color("TextPrimary"))
						
						DetailRow(
							icon: "calendar.badge.clock",
							title: "Payment Date",
							value: tax.paymentDate.formatted(date: .long, time: .omitted)
						)
						
						Divider()
							.background(Color("TextPrimary").opacity(0.1))
						
						DetailRow(
							icon: "calendar.badge.checkmark",
							title: "Valid Until",
							value: tax.validUntil.formatted(date: .long, time: .omitted),
							valueColor: statusColor
						)
						
						Divider()
							.background(Color("TextPrimary").opacity(0.1))
						
						DetailRow(
							icon: "mappin.circle.fill",
							title: "Payment Location",
							value: tax.location
						)
						
						if !tax.notes.isEmpty {
							Divider()
								.background(Color("TextPrimary").opacity(0.1))
							
							VStack(alignment: .leading, spacing: 8) {
								HStack(spacing: 8) {
									Image(systemName: "note.text")
										.foregroundColor(Color("AccentNeon"))
									Text("Notes")
										.font(.system(size: 14, weight: .semibold))
										.foregroundColor(.gray)
								}
								
								Text(tax.notes)
									.font(.system(size: 15))
									.foregroundColor(Color("TextPrimary"))
							}
						}
					}
					.padding()
					.background(
						RoundedRectangle(cornerRadius: 15)
							.fill(Color("CardBackground"))
					)
					
					// Reminder Info
					VStack(spacing: 12) {
						HStack(spacing: 8) {
							Image(systemName: "bell.badge.fill")
								.foregroundColor(Color("AccentNeon"))
							Text("Reminder Schedule")
								.font(.system(size: 16, weight: .semibold))
								.foregroundColor(Color("TextPrimary"))
							Spacer()
						}
						
						VStack(spacing: 8) {
							ReminderItem(days: 30, date: Calendar.current.date(byAdding: .day, value: -30, to: tax.validUntil)!)
							ReminderItem(days: 7, date: Calendar.current.date(byAdding: .day, value: -7, to: tax.validUntil)!)
							ReminderItem(days: 1, date: Calendar.current.date(byAdding: .day, value: -1, to: tax.validUntil)!)
						}
					}
					.padding()
					.background(
						RoundedRectangle(cornerRadius: 15)
							.fill(Color("CardBackground"))
					)
					
					// Delete Button
					Button(action: {
						showDeleteAlert = true
					}) {
						HStack {
							Image(systemName: "trash.fill")
							Text("Delete Record")
						}
						.font(.system(size: 16, weight: .semibold))
						.foregroundColor(.white)
						.frame(maxWidth: .infinity)
						.padding()
						.background(
							RoundedRectangle(cornerRadius: 12)
								.fill(Color.red.opacity(0.8))
						)
					}
					.padding(.top, 8)
				}
				.padding(.horizontal, 20)
				.padding(.bottom, 40)
			}
		}
		.navigationBarTitleDisplayMode(.inline)
		.toolbarBackground(Color("BackgroundPrimary"), for: .navigationBar)
		.toolbarBackground(.visible, for: .navigationBar)
		.alert("Delete Tax Record", isPresented: $showDeleteAlert) {
			Button("Cancel", role: .cancel) {}
			Button("Delete", role: .destructive) {
				taxManager.deleteTaxHistory(tax)
				dismiss()
			}
		} message: {
			Text("Are you sure you want to delete this tax record? This action cannot be undone.")
		}
	}
	
	var statusColor: Color {
		switch tax.status {
		case .valid: return .green
		case .expiringSoon: return .orange
		case .expired: return .red
		}
	}
}

// MARK: - Detail Row
struct DetailRow: View {
	let icon: String
	let title: String
	let value: String
	var valueColor: Color = Color("TextPrimary")
	
	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: icon)
				.font(.system(size: 18))
				.foregroundColor(Color("AccentNeon"))
				.frame(width: 24)
			
			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.system(size: 14, weight: .semibold))
					.foregroundColor(.gray)
				Text(value)
					.font(.system(size: 15))
					.foregroundColor(valueColor)
			}
			
			Spacer()
		}
	}
}

// MARK: - Reminder Item
struct ReminderItem: View {
	let days: Int
	let date: Date
	
	var isPast: Bool {
		date < Date()
	}
	
	var body: some View {
		HStack {
			HStack(spacing: 8) {
				Image(systemName: isPast ? "checkmark.circle.fill" : "bell.fill")
					.font(.system(size: 14))
					.foregroundColor(isPast ? .green : Color("AccentNeon"))
				
				Text("\(days) days before")
					.font(.system(size: 14))
					.foregroundColor(Color("TextPrimary"))
			}
			
			Spacer()
			
			Text(date.formatted(date: .abbreviated, time: .omitted))
				.font(.system(size: 13))
				.foregroundColor(.gray)
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 8)
		.background(
			RoundedRectangle(cornerRadius: 8)
				.fill(Color("BackgroundPrimary"))
		)
	}
}

#Preview {
	NavigationStack {
		TaxDetailView(tax: TaxModel.sampleData[0])
	}
	.preferredColorScheme(.dark)
}
