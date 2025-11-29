//
//  LocationManager.swift
//  DriveBuddy
//
//  Fixed version - Distance now shows properly
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
	private let locationManager = CLLocationManager()
	
	@Published var userLocation: CLLocation?
	@Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
	@Published var locationError: String?
	
	override init() {
		super.init()
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.distanceFilter = 10 // Update every 10 meters
		
		// Check current authorization status
		authorizationStatus = locationManager.authorizationStatus
		
		// If already authorized, start immediately
		if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
			startUpdatingLocation()
		}
	}
	
	func requestPermission() {
		locationManager.requestWhenInUseAuthorization()
	}
	
	func startUpdatingLocation() {
		print("🎯 Starting location updates...")
		locationManager.startUpdatingLocation()
		
		// Request location immediately
		locationManager.requestLocation()
	}
	
	func stopUpdatingLocation() {
		locationManager.stopUpdatingLocation()
	}
	
	// Calculate distance between user location and workshop
	func calculateDistance(to workshopCoordinate: CLLocationCoordinate2D) -> String {
		guard let userLocation = userLocation else {
			print("⚠️ User location is nil when calculating distance")
			return "-"
		}
		
		let workshopLocation = CLLocation(
			latitude: workshopCoordinate.latitude,
			longitude: workshopCoordinate.longitude
		)
		
		let distanceInMeters = userLocation.distance(from: workshopLocation)
		
		// Format distance
		if distanceInMeters < 1000 {
			return String(format: "%.0f m", distanceInMeters)
		} else {
			return String(format: "%.1f km", distanceInMeters / 1000)
		}
	}
	
	// Calculate distance and return as double (for sorting)
	func distanceInMeters(to workshopCoordinate: CLLocationCoordinate2D) -> Double? {
		guard let userLocation = userLocation else {
			return nil
		}
		
		let workshopLocation = CLLocation(
			latitude: workshopCoordinate.latitude,
			longitude: workshopCoordinate.longitude
		)
		
		return userLocation.distance(from: workshopLocation)
	}
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = locations.last else { return }
		
		print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
		
		// Update published property
		DispatchQueue.main.async {
			self.userLocation = location
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		locationError = error.localizedDescription
		print("❌ Location error: \(error.localizedDescription)")
	}
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		print("🔐 Authorization changed to: \(manager.authorizationStatus.rawValue)")
		
		DispatchQueue.main.async {
			self.authorizationStatus = manager.authorizationStatus
		}
		
		switch manager.authorizationStatus {
		case .authorizedWhenInUse, .authorizedAlways:
			print("✅ Location authorized, starting updates...")
			startUpdatingLocation()
		case .denied, .restricted:
			locationError = "Location access denied. Please enable in Settings."
			print("❌ Location access denied")
		case .notDetermined:
			print("⏳ Location permission not determined")
			requestPermission()
		@unknown default:
			break
		}
	}
}
