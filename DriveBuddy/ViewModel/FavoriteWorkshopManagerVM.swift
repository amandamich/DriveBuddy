//
//  FavoriteWorkshopManager.swift
//  DriveBuddy
//
//  Manages favorite workshops using UserDefaults
//

import Foundation
import Combine

class FavoriteWorkshopManagerVM: ObservableObject {
    static let shared = FavoriteWorkshopManagerVM()
    
    @Published var favoriteWorkshopIds: Set<String> = []
    
    private let favoritesKey = "favoriteWorkshops"
    
    init() {
        loadFavorites()
    }
    
    // Load favorites from UserDefaults
    func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favoriteWorkshopIds = decoded
        }
    }
    
    // Save favorites to UserDefaults
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteWorkshopIds) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }
    
    // Toggle favorite status
    func toggleFavorite(workshopId: String) {
        if favoriteWorkshopIds.contains(workshopId) {
            favoriteWorkshopIds.remove(workshopId)
        } else {
            favoriteWorkshopIds.insert(workshopId)
        }
        saveFavorites()
    }
    
    // Check if workshop is favorited
    func isFavorite(workshopId: String) -> Bool {
        return favoriteWorkshopIds.contains(workshopId)
    }
    
    // Get all favorite workshops
    func getFavoriteWorkshops(from allWorkshops: [Workshop]) -> [Workshop] {
        return allWorkshops.filter { favoriteWorkshopIds.contains($0.id.uuidString) }
    }
}
