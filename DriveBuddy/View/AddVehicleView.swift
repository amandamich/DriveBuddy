//
//  AddVehicleView.swift
//  DriveBuddy
//
//  Created by Timothy on 28/10/25.
//

import SwiftUI

struct AddVehicleView: View {
	@State private var makeAndModel: String = ""
	   @State private var vehicleType: String = "Car"
	   @State private var licensePlate: String = ""
	   @State private var year: String = ""
	   @State private var odometer: String = ""
	   @State private var taxDate: Date = Date()
	   @State private var taxReminder: Bool = true
	@State private var isAnimating = false
	
	let vehicleTypes = ["Car", "Motorbike"]

	var body: some View {
		ZStack {
			
			Color.black.opacity(0.95).ignoresSafeArea()

			VStack(alignment: .leading, spacing: 18) {
				VStack{
					// Header
					Text("Add New Vehicle")
						.font(.system(size: 36, weight: .bold, design: .rounded))
						.foregroundColor(.white)
						.shadow(color: .blue, radius: 10)
				}.padding(.leading)
				
				
				ScrollView(showsIndicators: false) {
					VStack(alignment: .leading, spacing: 18) {
						// Vehicle Type
						Group {
							Text("Vehicle Type")
								.foregroundColor(.white)
							Menu {
								ForEach(vehicleTypes, id: \.self) { type in
									Button(type) { vehicleType = type }
								}
							} label: {
								HStack {
									Text(vehicleType)
										.foregroundColor(.black)
									Spacer()
									Image(systemName: "chevron.down")
										.foregroundColor(.black)
								}
								.padding()
								.background(.white)
								.cornerRadius(10)
							}
						}
						
						// Make & Model
						Group {
							Text("Vehicle Model")
								.foregroundColor(.white)
							TextField("Honda Beat", text: $makeAndModel)
								.padding()
								.background(.white)
								.cornerRadius(10)
								.foregroundColor(.white)
						}
						
						
						
						// License Plate Number
						Group {
							Text("License Plate Number")
								.foregroundColor(.white)
							TextField("L 568 GX (Optional)", text: $licensePlate)
								.padding()
								.background(.white)
								.cornerRadius(10)
								.foregroundColor(.white)
						}
						
						// Year
						Group {
							Text("Year")
								.foregroundColor(.white)
							TextField("2005 (Optional)", text: $year)
								.padding()
								.background(.white)
								.cornerRadius(10)
								.foregroundColor(.white)
						}
						
						// Odometer
						Group {
							Text("Current Odometer / Mileage")
								.foregroundColor(.white)
							TextField("45000 (km)", text: $odometer)
								.padding()
								.background(.white)
								.cornerRadius(10)
								.foregroundColor(.white)
								.keyboardType(.numberPad)
						}
						
						// Tax Expiry Date
						Group {
							Text("Tax Expiry Date")
								.foregroundColor(.white)
							DatePicker(
								"",
								selection: $taxDate,
								displayedComponents: .date
							)
							.datePickerStyle(.compact)
							.labelsHidden()
							.padding(10)
							.frame(maxWidth: .infinity, alignment: .leading)
							.background(.white)
							.cornerRadius(10)
							.foregroundColor(.white)
						}
						
						// Tax Reminder
						HStack {
							Text("Tax Reminder")
								.foregroundColor(.white)
							Spacer()
							Toggle("", isOn: $taxReminder)
								.labelsHidden()
						}
						
						// History Service
						Text("History Last Service")
							.foregroundColor(.white)
						
						Button(action: {
							withAnimation(.easeInOut(duration: 0.3)) {
								isAnimating.toggle()
							}
						}) {
							Text("Add Vehicle")
								.font(.headline)
								.foregroundColor(.white)
								.padding()
								.frame(maxWidth: .infinity)
								.background(
									RoundedRectangle(cornerRadius: 12)
										.stroke(Color.cyan, lineWidth: 2)
										.shadow(color: .blue, radius: 8)
										.background(
											RoundedRectangle(cornerRadius: 12)
												.fill(Color.black.opacity(0.5))
										)
								)
							.shadow(color: .blue, radius: 10)}
					}
					.padding(.horizontal, 20)
					.padding(.bottom, 100)
				}
				
				Spacer()
			}
		}

	}
}

#Preview {
    AddVehicleView()
}
