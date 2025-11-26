//
//  TaxModel.swift
//  DriveBuddy
//
//  Created by Timothy on 26/11/25.
//
import Foundation

struct TaxModel: Identifiable, Codable {
	var id = UUID()
	var vehiclePlate: String          // Plat nomor
	var vehicleName: String            // Nama kendaraan (e.g., "Honda Civic 2020")
	var taxAmount: Double              // Nominal pajak
	var paymentDate: Date              // Tanggal bayar
	var validUntil: Date               // Berlaku sampai
	var location: String               // Lokasi pembayaran (Samsat)
	var notes: String                  // Catatan tambahan
	var receiptImagePath: String?      // Path foto bukti bayar (optional)
	
	// Computed property untuk cek status
	var status: TaxStatus {
		let now = Date()
		let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: validUntil).day ?? 0
		
		if daysUntilExpiry < 0 {
			return .expired
		} else if daysUntilExpiry <= 30 {
			return .expiringSoon
		} else {
			return .valid
		}
	}
	
	// Days until expiry
	var daysUntilExpiry: Int {
		Calendar.current.dateComponents([.day], from: Date(), to: validUntil).day ?? 0
	}
	
	// Format currency
	var formattedAmount: String {
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.currencyCode = "IDR"
		formatter.locale = Locale(identifier: "id_ID")
		return formatter.string(from: NSNumber(value: taxAmount)) ?? "Rp \(taxAmount)"
	}
}

enum TaxStatus: String, Codable {
	case valid = "Valid"
	case expiringSoon = "Expiring Soon"
	case expired = "Expired"
	
	var color: String {
		switch self {
		case .valid:
			return "green"
		case .expiringSoon:
			return "orange"
		case .expired:
			return "red"
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
			paymentDate: Date().addingTimeInterval(-60 * 24 * 60 * 60), // 60 days ago
			validUntil: Date().addingTimeInterval(305 * 24 * 60 * 60), // 305 days from now
			location: "Samsat Jakarta Timur",
			notes: "Pembayaran tepat waktu"
		),
		TaxModel(
			vehiclePlate: "B 5678 ABC",
			vehicleName: "Toyota Avanza 2019",
			taxAmount: 1800000,
			paymentDate: Date().addingTimeInterval(-400 * 24 * 60 * 60), // 400 days ago
			validUntil: Date().addingTimeInterval(-35 * 24 * 60 * 60), // Expired 35 days ago
			location: "Samsat Jakarta Barat",
			notes: "Perlu segera diperpanjang"
		),
		TaxModel(
			vehiclePlate: "B 9012 DEF",
			vehicleName: "Suzuki Ertiga 2021",
			taxAmount: 2100000,
			paymentDate: Date().addingTimeInterval(-335 * 24 * 60 * 60),
			validUntil: Date().addingTimeInterval(25 * 24 * 60 * 60), // 25 days from now
			location: "Samsat Jakarta Selatan",
			notes: "Segera habis masa berlaku"
		)
	]
}
