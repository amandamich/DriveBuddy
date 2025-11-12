//
//  LocationManager.swift
//  DriveBuddy
//
//  Created by Timothy on 12/11/25.
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
	}
	
	func requestPermission() {
		locationManager.requestWhenInUseAuthorization()
	}
	
	func startUpdatingLocation() {
		locationManager.startUpdatingLocation()
	}
	
	func stopUpdatingLocation() {
		locationManager.stopUpdatingLocation()
	}
	
	// Calculate distance between user location and workshop
	func calculateDistance(to workshopCoordinate: CLLocationCoordinate2D) -> String {
		guard let userLocation = userLocation else {
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
		userLocation = location
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		locationError = error.localizedDescription
		print("Location error: \(error.localizedDescription)")
	}
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		authorizationStatus = manager.authorizationStatus
		
		switch manager.authorizationStatus {
		case .authorizedWhenInUse, .authorizedAlways:
			startUpdatingLocation()
		case .denied, .restricted:
			locationError = "Location access denied. Please enable in Settings."
		case .notDetermined:
			requestPermission()
		@unknown default:
			break
		}
	}
}
