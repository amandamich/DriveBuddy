//
//  FavoriteButton.swift
//  DriveBuddy
//
//  Reusable favorite button component
//

import SwiftUI

struct FavoriteButtonVM: View {
    let workshopId: String
    @ObservedObject var favoriteManager: FavoriteWorkshopManagerVM
    let size: CGFloat
    let isDarkMode: Bool
    
    init(workshopId: String,
         favoriteManager: FavoriteWorkshopManagerVM = .shared,
         size: CGFloat = 24,
         isDarkMode: Bool = true) {
        self.workshopId = workshopId
        self.favoriteManager = favoriteManager
        self.size = size
        self.isDarkMode = isDarkMode
    }
    
    private var isFavorite: Bool {
        favoriteManager.isFavorite(workshopId: workshopId)
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                favoriteManager.toggleFavorite(workshopId: workshopId)
            }
        }) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: size))
                .foregroundColor(isFavorite ? .red : (isDarkMode ? .white.opacity(0.8) : .gray))
                .scaleEffect(isFavorite ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFavorite)
        }
    }
}
