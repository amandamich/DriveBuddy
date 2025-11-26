//
//  AddTaxView.swift
//  DriveBuddy
//
//  Created by Timothy on 26/11/25.
//

import SwiftUI

struct AddTaxView: View {
	@Environment(\.dismiss) var dismiss
	@StateObject private var taxManager = TaxHistoryManager.shared
	
	@State private var vehiclePlate = ""
	@State private var vehicleName = ""
	@State private var taxAmount = ""
	@State private var paymentDate = Date()
	@State private var validUntil = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()
	@State private var location = ""
	@State private var notes = ""
	
	@State private var showAlert = false
	@State private var alertMessage = ""
	
	var body: some View {
		NavigationStack {
			ZStack {
				Color("BackgroundPrimary")
					.ignoresSafeArea()
				
				ScrollView(showsIndicators: false) {
					VStack(spacing: 24) {
						Text("Add Tax Record")
							.font(.system(size: 34, weight: .bold))
							.foregroundColor(Color("TextPrimary"))
						// Header Icon
						ZStack {
							Circle()
								.fill(Color("AccentNeon").opacity(0.2))
								.frame(width: 80, height: 80)
							
							Image(systemName: "doc.text.fill")
								.font(.system(size: 36))
								.foregroundColor(Color("AccentNeon"))
						}
						.padding(.bottom, 20)
						
						VStack(alignment: .leading, spacing: 20) {
							// Vehicle Plate
							FormField(
								title: "Vehicle Plate Number",
								icon: "car.fill",
								placeholder: "e.g., B 1234 XYZ",
								text: $vehiclePlate
							)
							.textInputAutocapitalization(.characters)
							
							// Vehicle Name
							FormField(
								title: "Vehicle Name",
								icon: "info.circle.fill",
								placeholder: "e.g., Honda Civic 2020",
								text: $vehicleName
							)
							
							// Tax Amount
							VStack(alignment: .leading, spacing: 8) {
								Label {
									Text("Tax Amount")
										.foregroundColor(Color("TextPrimary"))
								} icon: {
									Image(systemName: "banknote.fill")
										.foregroundColor(Color("AccentNeon"))
								}
								
								HStack {
									Text("Rp")
										.foregroundColor(.gray)
									TextField("0", text: $taxAmount)
										.keyboardType(.numberPad)
										.foregroundColor(Color("TextPrimary"))
								}
								.padding()
								.background(Color("CardBackground"))
								.cornerRadius(12)
							}
							
							// Payment Date
							VStack(alignment: .leading, spacing: 8) {
								Label {
									Text("Payment Date")
										.foregroundColor(Color("TextPrimary"))
								} icon: {
									Image(systemName: "calendar.badge.clock")
										.foregroundColor(Color("AccentNeon"))
								}
								
								DatePicker("", selection: $paymentDate, displayedComponents: .date)
									.datePickerStyle(.compact)
									.labelsHidden()
									.tint(Color("AccentNeon"))
									.padding()
									.background(Color("CardBackground"))
									.cornerRadius(12)
							}
							
							// Valid Until
							VStack(alignment: .leading, spacing: 8) {
								Label {
									Text("Valid Until")
										.foregroundColor(Color("TextPrimary"))
								} icon: {
									Image(systemName: "calendar.badge.checkmark")
										.foregroundColor(Color("AccentNeon"))
								}
								
								DatePicker("", selection: $validUntil, displayedComponents: .date)
									.datePickerStyle(.compact)
									.labelsHidden()
									.tint(Color("AccentNeon"))
									.padding()
									.background(Color("CardBackground"))
									.cornerRadius(12)
							}
							
							// Location
							FormField(
								title: "Payment Location",
								icon: "mappin.circle.fill",
								placeholder: "e.g., Samsat Jakarta Timur",
								text: $location
							)
							
							// Notes
							VStack(alignment: .leading, spacing: 8) {
								Label {
									Text("Notes (Optional)")
										.foregroundColor(Color("TextPrimary"))
								} icon: {
									Image(systemName: "note.text")
										.foregroundColor(Color("AccentNeon"))
								}
								
								TextEditor(text: $notes)
									.frame(height: 100)
									.padding(8)
									.background(Color("CardBackground"))
									.cornerRadius(12)
									.foregroundColor(Color("TextPrimary"))
									.scrollContentBackground(.hidden)
							}
						}
						
						// Reminder Info Card
						HStack(spacing: 12) {
							Image(systemName: "bell.badge.fill")
								.font(.system(size: 24))
								.foregroundColor(Color("AccentNeon"))
							
							VStack(alignment: .leading, spacing: 4) {
								Text("Auto Reminder")
//									.font(.system(size: 14, weight: .semibold))
									.foregroundColor(Color("TextPrimary"))
								Text("You'll be notified 30, 7, and 1 day before expiry")
//									.font(.system(size: 14))
									.foregroundColor(.gray)
							}
						}
						.padding()
						.frame(maxWidth: .infinity, alignment: .leading)
						.background(
							RoundedRectangle(cornerRadius: 12)
								.fill(Color("AccentNeon").opacity(0.1))
						)
						
						// Save Button
						Button(action: saveTaxHistory) {
							Text("Save Tax Record")
								.font(.headline)
								.foregroundColor(isFormValid ? .white : .gray)
								.padding()
								.frame(maxWidth: .infinity)
								.background(
									RoundedRectangle(cornerRadius: 12)
										.stroke(isFormValid ? Color.cyan : Color.gray.opacity(0.5), lineWidth: 2)
										.shadow(color: isFormValid ? .blue : .clear, radius: 8)
										.background(
											RoundedRectangle(cornerRadius: 12)
												.fill(Color.black.opacity(0.5))
										)
								)
								.shadow(color: isFormValid ? .blue : .clear, radius: 10)
						}
						.disabled(!isFormValid)
						.padding(.top, 8)
					}
					.padding(.horizontal, 20)
					.padding(.bottom, 40)
				}
			}
//			.navigationTitle("Add Tax Record")
//			.navigationBarTitleDisplayMode(.inline)
//			.toolbar {
//				ToolbarItem(placement: .navigationBarLeading) {
//					Button("Cancel") {
//						dismiss()
//					}
//					.foregroundColor(Color("AccentNeon"))
//				}
//			}
			.toolbarBackground(Color("BackgroundPrimary"), for: .navigationBar)
			.toolbarBackground(.visible, for: .navigationBar)
			.alert("Success", isPresented: $showAlert) {
				Button("OK") {
					dismiss()
				}
			} message: {
				Text(alertMessage)
			}
		}
	}
	
	var isFormValid: Bool {
		!vehiclePlate.isEmpty &&
		!vehicleName.isEmpty &&
		!taxAmount.isEmpty &&
		Double(taxAmount) != nil &&
		!location.isEmpty &&
		validUntil > paymentDate
	}
	
	func saveTaxHistory() {
		guard let amount = Double(taxAmount) else { return }
		
		let newTax = TaxModel(
			vehiclePlate: vehiclePlate,
			vehicleName: vehicleName,
			taxAmount: amount,
			paymentDate: paymentDate,
			validUntil: validUntil,
			location: location,
			notes: notes
		)
		
		taxManager.addTaxHistory(newTax)
		
		alertMessage = "Tax record saved successfully! Reminders have been set."
		showAlert = true
	}
}

// MARK: - Form Field Component
struct FormField: View {
	let title: String
	let icon: String
	let placeholder: String
	@Binding var text: String
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Label {
				Text(title)
//					.font(.system(size: 14, weight: .semibold))
					.foregroundColor(Color("TextPrimary"))
			} icon: {
				Image(systemName: icon)
					.foregroundColor(Color("AccentNeon"))
			}
			
			TextField(placeholder, text: $text)
				.padding()
				.background(Color("CardBackground"))
				.cornerRadius(12)
				.foregroundColor(Color("TextPrimary"))
				.autocorrectionDisabled(true)
		}
	}
}

#Preview {
	AddTaxView()
		.preferredColorScheme(.dark)
}
