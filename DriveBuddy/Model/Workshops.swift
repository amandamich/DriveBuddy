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
	let phoneNumber: String  // ← NEW: WhatsApp number
	
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
			services: ["AC Car", "Spooring Balancing", "Tune Up", "Oil Change and Matic"],
			phoneNumber: "681254569197"
		),
		Workshop(
			name: "Bengkel Jaya Anda Surabaya",
			address: "Jl. Ngagel Tim. No.25, Pucang Sewu, Kec. Gubeng",
			coordinate: CLLocationCoordinate2D(latitude: -7.2925, longitude: 112.7525),
			openHours: "Monday, 08:00am - 17:00pm",
			rating: 4.9,
			reviewCount: 2955,
			services: ["Specialist onderstel / understelsel"],
			phoneNumber: "6289613866920"
		),
		Workshop(
			name: "Mobeng Jemusari",
			address: "Jl. Raya Jemusari No.190, Kendangsari, Kec. Tenggilis Mejoyo",
			coordinate: CLLocationCoordinate2D(latitude: -7.3365, longitude: 112.7698),
			openHours: "Monday, 09:00am - 21:00pm",
			rating: 4.6,
			reviewCount: 519,
			services: ["Oil Change", "Spare parts"],
			phoneNumber: "6281279172289"
		),
		Workshop(
			name: "FT Garage",
			address: "Jl. Raya Kedung Asem No.99, Kedung Baruk, Kec. Rungkut",
			coordinate: CLLocationCoordinate2D(latitude: -7.3401, longitude: 112.7822),
			openHours: "Monday, 08:30am - 17:00pm",
			rating: 4.9,
			reviewCount: 0,
			services: ["Tune Up", "AC Car", "Scale Service", "Scanner", "Remap ECU"],
			phoneNumber: "6281279172289"
		),
		Workshop(
			name: "Bengkel Mobil 88",
			address: "Jl. Raya Darmo No.88, Darmo, Kec. Wonokromo",
			coordinate: CLLocationCoordinate2D(latitude: -7.2815, longitude: 112.7318),
			openHours: "Monday - Saturday, 08:00am - 18:00pm",
			rating: 4.7,
			reviewCount: 845,
			services: ["General Service", "Engine Repair", "Transmission", "AC Service"],
			phoneNumber: "628123238789"
		),
		Workshop(
			name: "Auto Care Plus",
			address: "Jl. Ahmad Yani No.156, Gayungan",
			coordinate: CLLocationCoordinate2D(latitude: -7.3214, longitude: 112.7286),
			openHours: "Monday - Sunday, 09:00am - 20:00pm",
			rating: 4.8,
			reviewCount: 1234,
			services: ["Car Wash", "Detailing", "Coating", "Polish"],
			phoneNumber: "628123238789"
		),
		Workshop(
			name: "Bengkel Resmi Honda",
			address: "Jl. Mayjend Sungkono No.89, Dukuh Pakis",
			coordinate: CLLocationCoordinate2D(latitude: -7.2847, longitude: 112.7194),
			openHours: "Monday - Saturday, 08:00am - 17:00pm",
			rating: 4.9,
			reviewCount: 2156,
			services: ["Authorized Service", "Spare Parts", "Body Repair", "Warranty Service"],
			phoneNumber: "628123238789"
		),
		Workshop(
			name: "Tire Master Surabaya",
			address: "Jl. Raya Kalirungkut No.45, Rungkut",
			coordinate: CLLocationCoordinate2D(latitude: -7.3356, longitude: 112.7789),
			openHours: "Monday - Saturday, 08:30am - 18:00pm",
			rating: 4.6,
			reviewCount: 678,
			services: ["Tire Change", "Wheel Alignment", "Balancing", "Tire Sales"],
			phoneNumber: "6281254569197"
		),
        Workshop(
            name: "Bengkel Mobil Karya Abadi",
            address: "Jl. Lakarsantri No.124, Lakarsantri, Kec. Lakarsantri",
            coordinate: CLLocationCoordinate2D(latitude: -7.3558, longitude: 112.6722),
            openHours: "Open 24 hours",
            rating: 4.9,
            reviewCount: 49,
			services: ["General Repair", "24 Hour Service", "Emergency Service"],
			phoneNumber: "628123238789"
        ),

        Workshop(
            name: "Jaya Anda Workshop - Car Suspension Specialist",
            address: "Jl. Ngagel Tim. No.25, Pucang Sewu, Kec. Gubeng",
            coordinate: CLLocationCoordinate2D(latitude: -7.2925, longitude: 112.7525),
            openHours: "Open · Closes 5:00 PM",
            rating: 4.9,
            reviewCount: 2900,
            services: ["Suspension Specialist", "Understel", "Spooring Balancing"],
			phoneNumber: "628123238789"
        ),

        Workshop(
            name: "Bengkel Metropolis",
            address: "Jl. Bukit Darmo Golf I No.3, Pradahkalikendal, Kec. Dukuhpakis",
            coordinate: CLLocationCoordinate2D(latitude: -7.2847, longitude: 112.7156),
            openHours: "Open · Closes 6:00 PM",
            rating: 4.7,
            reviewCount: 59,
            services: ["Car Repair", "Maintenance", "General Service"],
			phoneNumber: "628123238789"
        ),

        Workshop(
            name: "Bengkel Dunia Mobil Surabaya",
            address: "Jl. Kenjeran No.323, Bulak, Kec. Bulak",
            coordinate: CLLocationCoordinate2D(latitude: -7.2289, longitude: 112.7644),
            openHours: "Open · Closes 4:30 PM",
            rating: 5.0,
            reviewCount: 268,
            services: ["Auto Repair", "Body Paint", "Engine Service"],
			phoneNumber: "628123238789"
        ),

        Workshop(
            name: "Bengkel Mobil FT Garage Kedung Asem",
            address: "Jl. Raya Kedung Asem No.99, Kedung Baruk, Kec. Rungkut",
            coordinate: CLLocationCoordinate2D(latitude: -7.3401, longitude: 112.7822),
            openHours: "Open · Closes 5:00 PM",
            rating: 4.9,
            reviewCount: 519,
            services: ["Auto Repair Shop", "General Service", "Maintenance"],
			phoneNumber: "628123238789"
        ),

        Workshop(
            name: "Bengkel Panggilan Noviant Remaap ECU",
            address: "Jl. Bengawan No.8, Darmo, Kec. Wonokromo",
            coordinate: CLLocationCoordinate2D(latitude: -7.2889, longitude: 112.7311),
            openHours: "Open 24 hours",
            rating: 5.0,
            reviewCount: 264,
            services: ["ECU Remapping", "Mobile Service", "24 Hour Service"],
			phoneNumber: "628123238789"
        ),

        Workshop(
            name: "Bengkel Panggilan 24 Jam Mitra Mekanik Surabaya",
            address: "Jl. Gubeng Kertajaya VII C No.29, Kertajaya, Kec. Gubeng",
            coordinate: CLLocationCoordinate2D(latitude: -7.2836, longitude: 112.7522),
            openHours: "Open 24 hours",
            rating: 4.7,
            reviewCount: 59,
            services: ["Mobile Service", "24 Hour Service", "Emergency Repair"],
			phoneNumber: "628123238789"
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
		services: [String],
		phoneNumber: String
	) -> Workshop {
		return Workshop(
			name: name,
			address: address,
			coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
			openHours: openHours,
			rating: rating,
			reviewCount: reviewCount,
			services: services,
			phoneNumber: phoneNumber
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
