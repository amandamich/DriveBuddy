//
//  Workshops.swift
//  DriveBuddy
//
//  Created by Timothy on 12/11/25.
//

import Foundation
import CoreLocation

struct Workshop: Identifiable {
	let id = UUID()
	let name: String
	let address: String
	let coordinate: CLLocationCoordinate2D
	let openHours: String
	let rating: Double
	let reviewCount: Int
	let services: [String]
	
	// Properties untuk menyimpan jarak yang sudah dihitung
	var distance: String = "-"
	var distanceInMeters: Double?
	
	// Sample data workshops di Surabaya dengan koordinat real
	static let sampleWorkshops: [Workshop] = [
		Workshop(
			name: "Bengkel Harris Mobil Surabaya",
			address: "Jl. Raya Kendangsari No.21, Kendangsari, Kec. Tenggilis Mejoyo",
			coordinate: CLLocationCoordinate2D(latitude: -7.3329, longitude: 112.7663),
			openHours: "Monday, 08:30am - 17:00pm",
			rating: 4.9,
			reviewCount: 1613,
			services: ["AC Car", "Spooring Balancing", "Tune Up", "Oil Change and Matic"]
		),
		Workshop(
			name: "Bengkel Jaya Anda Surabaya",
			address: "Jl. Ngagel Tim. No.25, Pucang Sewu, Kec. Gubeng",
			coordinate: CLLocationCoordinate2D(latitude: -7.2925, longitude: 112.7525),
			openHours: "Monday, 08:00am - 17:00pm",
			rating: 4.9,
			reviewCount: 2955,
			services: ["Specialist onderstel / understelsel"]
		),
		Workshop(
			name: "Mobeng Jemusari",
			address: "Jl. Raya Jemusari No.190, Kendangsari, Kec. Tenggilis Mejoyo",
			coordinate: CLLocationCoordinate2D(latitude: -7.3365, longitude: 112.7698),
			openHours: "Monday, 09:00am - 21:00pm",
			rating: 4.6,
			reviewCount: 519,
			services: ["Oil Change", "Spare parts"]
		),
		Workshop(
			name: "FT Garage",
			address: "Jl. Raya Kedung Asem No.99, Kedung Baruk, Kec. Rungkut",
			coordinate: CLLocationCoordinate2D(latitude: -7.3401, longitude: 112.7822),
			openHours: "Monday, 08:30am - 17:00pm",
			rating: 4.9,
			reviewCount: 0,
			services: []
		),
		Workshop(
			name: "Bengkel Mobil 88",
			address: "Jl. Raya Darmo No.88, Darmo, Kec. Wonokromo",
			coordinate: CLLocationCoordinate2D(latitude: -7.2815, longitude: 112.7318),
			openHours: "Monday - Saturday, 08:00am - 18:00pm",
			rating: 4.7,
			reviewCount: 845,
			services: ["General Service", "Engine Repair", "Transmission", "AC Service"]
		),
		Workshop(
			name: "Auto Care Plus",
			address: "Jl. Ahmad Yani No.156, Gayungan",
			coordinate: CLLocationCoordinate2D(latitude: -7.3214, longitude: 112.7286),
			openHours: "Monday - Sunday, 09:00am - 20:00pm",
			rating: 4.8,
			reviewCount: 1234,
			services: ["Car Wash", "Detailing", "Coating", "Polish"]
		),
		Workshop(
			name: "Bengkel Resmi Honda",
			address: "Jl. Mayjend Sungkono No.89, Dukuh Pakis",
			coordinate: CLLocationCoordinate2D(latitude: -7.2847, longitude: 112.7194),
			openHours: "Monday - Saturday, 08:00am - 17:00pm",
			rating: 4.9,
			reviewCount: 2156,
			services: ["Authorized Service", "Spare Parts", "Body Repair", "Warranty Service"]
		),
		Workshop(
			name: "Tire Master Surabaya",
			address: "Jl. Raya Kalirungkut No.45, Rungkut",
			coordinate: CLLocationCoordinate2D(latitude: -7.3356, longitude: 112.7789),
			openHours: "Monday - Saturday, 08:30am - 18:00pm",
			rating: 4.6,
			reviewCount: 678,
			services: ["Tire Change", "Wheel Alignment", "Balancing", "Tire Sales"]
		)
	]
}

// MARK: - Extension untuk menambah workshop baru
extension Workshop {
	// Helper function untuk create workshop baru
	static func create(
		name: String,
		address: String,
		latitude: Double,
		longitude: Double,
		openHours: String,
		rating: Double,
		reviewCount: Int,
		services: [String]
	) -> Workshop {
		return Workshop(
			name: name,
			address: address,
			coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
			openHours: openHours,
			rating: rating,
			reviewCount: reviewCount,
			services: services
		)
	}
}

// MARK: - Tips untuk mendapatkan koordinat dari Google Maps:
/*
 1. Buka Google Maps di browser atau app
 2. Cari lokasi bengkel yang diinginkan
 3. Klik kanan pada lokasi tersebut
 4. Pilih "What's here?" atau lihat koordinat yang muncul
 5. Koordinat akan muncul dalam format: -7.3329, 112.7663
 6. Gunakan format tersebut di CLLocationCoordinate2D:
	CLLocationCoordinate2D(latitude: -7.3329, longitude: 112.7663)
 
 Catatan:
 - Latitude adalah koordinat vertikal (Utara-Selatan)
 - Longitude adalah koordinat horizontal (Barat-Timur)
 - Untuk Surabaya, latitude sekitar -7.2 sampai -7.4 (negatif karena di belahan selatan)
 - Longitude sekitar 112.6 sampai 112.8
 */
