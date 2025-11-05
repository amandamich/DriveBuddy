//
//  EditVehicleView.swift
//  DriveBuddy
//
//  Created by student on 05/11/25.
//

import SwiftUI

struct EditVehicleView: View {
    @Environment(\.dismiss) private var dismiss

    // Kita edit salinan lokal
    @State private var working: Vehicle
    let onSave: (Vehicle) -> Void

    // Init: bawa kendaraan awal, jadikan @State
    init(vehicle: Vehicle, onSave: @escaping (Vehicle) -> Void) {
        _working = State(initialValue: vehicle)
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Edit Vehicle")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top)

                    VStack(alignment: .leading, spacing: 12) {
                        Group {
                            Text("Make & Model").foregroundColor(.white)
                            TextField("Enter model", text: $working.makeAndModel)
                                .textFieldStyle(CustomTextFieldStyle())

                            Text("License Plate").foregroundColor(.white)
                            TextField("Enter plate", text: $working.licensePlate)
                                .textFieldStyle(CustomTextFieldStyle())

                            Text("Odometer").foregroundColor(.white)
                            TextField("Enter odometer", text: $working.odometer)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(15)

                    Button {
                        onSave(working)   // kirim balik hasil edit
                        dismiss()
                    } label: {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(20)
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal)
            }
        }
    }
}
