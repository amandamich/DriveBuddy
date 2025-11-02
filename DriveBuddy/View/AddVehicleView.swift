import SwiftUI

struct AddVehicleView: View {
    @Environment(\.dismiss) var dismiss
    var onAdd: (Vehicle) -> Void

    @State private var makeAndModel: String = ""
    @State private var vehicleType: String = "Car"
    @State private var licensePlate: String = ""
    @State private var year: String = ""
    @State private var odometer: String = ""
    @State private var taxDate: Date = Date()
    @State private var taxReminder: Bool = true

    let vehicleTypes = ["Car", "Motorbike"]

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text("Add New Vehicle")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
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
                                }
                                .padding()
                                .background(.white)
                                .cornerRadius(10)
                            }
                        }

                        TextField("Vehicle Model", text: $makeAndModel)
                            .padding()
                            .background(.white)
                            .cornerRadius(10)

                        TextField("License Plate", text: $licensePlate)
                            .padding()
                            .background(.white)
                            .cornerRadius(10)

                        TextField("Year", text: $year)
                            .padding()
                            .background(.white)
                            .cornerRadius(10)

                        TextField("Odometer (km)", text: $odometer)
                            .padding()
                            .background(.white)
                            .cornerRadius(10)
                            .keyboardType(.numberPad)

                        Text("Tax Expiry Date")
                            .foregroundColor(.white)
                        DatePicker("", selection: $taxDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding()
                            .background(.white)
                            .cornerRadius(10)

                        Button(action: {
                            let newVehicle = Vehicle(
                                makeAndModel: makeAndModel,
                                vehicleType: vehicleType,
                                licensePlate: licensePlate,
                                year: year,
                                odometer: odometer,
                                taxDate: taxDate
                            )
                            onAdd(newVehicle)
                            dismiss()
                        }) {
                            Text("Add Vehicle")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    AddVehicleView { _ in }
}
