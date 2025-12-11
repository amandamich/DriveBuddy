//
//  FavoriteWorkshopManager.swift
//  DriveBuddy
//
//  Manages favorite workshops with user-specific storage (Core Data)
//

import Foundation
import Combine

class FavoriteWorkshopManagerVM: ObservableObject {
    static let shared = FavoriteWorkshopManagerVM()
    
    @Published var favoriteWorkshopIds: Set<String> = []
    
    private let favoritesKeyPrefix = "favoriteWorkshops_"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen for login/logout notifications
        setupNotificationObservers()
        loadFavorites()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // Setup notification observers for auth state changes
    private func setupNotificationObservers() {
        // Listen for user login
        NotificationCenter.default.publisher(for: .userDidLogin)
            .sink { [weak self] _ in
                self?.loadFavorites()
            }
            .store(in: &cancellables)
        
        // Listen for user logout
        NotificationCenter.default.publisher(for: .userDidLogout)
            .sink { [weak self] _ in
                self?.clearFavorites()
            }
            .store(in: &cancellables)
    }
    
    // Get current user ID from UserDefaults
    private func getCurrentUserId() -> String? {
        return UserDefaults.standard.string(forKey: "currentUserId")
    }
    
    // Get user-specific UserDefaults key
    private func getUserSpecificKey() -> String? {
        guard let userId = getCurrentUserId() else {
            return nil
        }
        return favoritesKeyPrefix + userId
    }
    
    // Load favorites from UserDefaults for current user
    func loadFavorites() {
        guard let key = getUserSpecificKey(),
              let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            favoriteWorkshopIds = []
            return
        }
        favoriteWorkshopIds = decoded
    }
    
    // Save favorites to UserDefaults for current user
    private func saveFavorites() {
        guard let key = getUserSpecificKey(),
              let encoded = try? JSONEncoder().encode(favoriteWorkshopIds) else {
            return
        }
        UserDefaults.standard.set(encoded, forKey: key)
    }
    
    // Clear favorites (used on logout)
    private func clearFavorites() {
        favoriteWorkshopIds = []
    }
    
    // Toggle favorite status
    func toggleFavorite(workshopId: String) {
        // Check if user is authenticated
        guard getCurrentUserId() != nil else {
            print("User must be logged in to favorite workshops")
            return
        }
        
        if favoriteWorkshopIds.contains(workshopId) {
            favoriteWorkshopIds.remove(workshopId)
        } else {
            favoriteWorkshopIds.insert(workshopId)
        }
        saveFavorites()
    }
    
    // Check if workshop is favorited
    func isFavorite(workshopId: String) -> Bool {
        // Return false if not authenticated
        guard getCurrentUserId() != nil else {
            return false
        }
        return favoriteWorkshopIds.contains(workshopId)
    }
    
    // Get all favorite workshops
    func getFavoriteWorkshops(from allWorkshops: [Workshop]) -> [Workshop] {
        return allWorkshops.filter { favoriteWorkshopIds.contains($0.id.uuidString) }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
}
