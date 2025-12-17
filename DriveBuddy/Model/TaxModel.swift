//
//  TaxModel.swift
//  DriveBuddy
//

import Foundation

struct TaxModel: Identifiable, Codable {
    var id = UUID()
    var vehiclePlate: String
    var vehicleName: String
    var taxAmount: Double
    var paymentDate: Date
    var validUntil: Date
    var location: String
    var notes: String
    var receiptImagePath: String?
    
    // ✅ NEW: Payment tracking
    var isPaid: Bool = false
    var actualPaymentDate: Date? = nil  // When they actually paid (for history)
    var isHistoryRecord: Bool = false   // True if this is a past record
    
    // Computed property for status
    var status: TaxStatus {
        let now = Date()
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: validUntil).day ?? 0
        
        if isPaid && daysUntilExpiry < 0 {
            return .expiredPaid  // ✅ NEW STATUS
        } else if daysUntilExpiry < 0 {
            return .expired
        } else if daysUntilExpiry <= 30 {
            return .expiringSoon
        } else {
            return .paid  // ✅ CHANGED FROM .valid
        }
    }
    
    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: validUntil).day ?? 0
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: NSNumber(value: taxAmount)) ?? "Rp \(taxAmount)"
    }
}

enum TaxStatus: String, Codable {
    case paid = "Paid"              // ✅ CHANGED FROM valid
    case expiringSoon = "Expiring Soon"
    case expired = "Expired"
    case expiredPaid = "Expired (Paid)"  // ✅ NEW STATUS
    
    var color: String {
        switch self {
        case .paid:
            return "green"
        case .expiringSoon:
            return "orange"
        case .expired:
            return "red"
        case .expiredPaid:
            return "gray"
        }
    }
}

// Sample data
extension TaxModel {
    static let sampleData: [TaxModel] = [
        TaxModel(
            vehiclePlate: "B 1234 XYZ",
            vehicleName: "Honda Civic 2020",
            taxAmount: 2500000,
            paymentDate: Date().addingTimeInterval(-60 * 24 * 60 * 60),
            validUntil: Date().addingTimeInterval(305 * 24 * 60 * 60),
            location: "Samsat Jakarta Timur",
            notes: "Pembayaran tepat waktu",
            isPaid: true,
            actualPaymentDate: Date().addingTimeInterval(-60 * 24 * 60 * 60)
        ),
        TaxModel(
            vehiclePlate: "B 5678 ABC",
            vehicleName: "Toyota Avanza 2019",
            taxAmount: 1800000,
            paymentDate: Date().addingTimeInterval(-400 * 24 * 60 * 60),
            validUntil: Date().addingTimeInterval(-35 * 24 * 60 * 60),
            location: "Samsat Jakarta Barat",
            notes: "Perlu segera diperpanjang",
            isPaid: false
        )
    ]
}
