//
//  Vehicle.swift
//  DriveBuddy
//
//  Created by Antonius Trimaryono on 02/11/25.
//

import Foundation

struct Vehicle: Identifiable, Codable {
    var id = UUID()
    var makeAndModel: String
    var vehicleType: String
    var licensePlate: String
    var year: String
    var odometer: String
    var taxDate: Date
}
