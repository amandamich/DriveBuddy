//
//  FavoriteWorkshopsView.swift
//  DriveBuddy
//
//  View for displaying all favorite workshops
//

import SwiftUI

struct FavoriteWorkshopsView: View {
    @StateObject private var favoriteManager = FavoriteWorkshopManagerVM.shared
    @Environment(\.colorScheme) private var colorScheme
    
    // Get all workshops from sample data
    private var allWorkshops: [Workshop] {
        Workshop.sampleWorkshops
    }
    
    private var favoriteWorkshops: [Workshop] {
        favoriteManager.getFavoriteWorkshops(from: allWorkshops)
    }
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        ZStack {
            // Background
            Color("BackgroundPrimary")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Title (No custom back button, use default)
                Text("Favorite Workshops")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color("TextPrimary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                
                Divider()
                    .background(Color("TextPrimary").opacity(0.15))
                
                // Content
                if favoriteWorkshops.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "heart.slash")
                            .font(.system(size: 70))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No Favorite Workshops Yet")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color("TextPrimary"))
                        
                        Text("Start adding workshops to your favorites by tapping the heart icon")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                } else {
                    // Workshop List
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 15) {
                            ForEach(favoriteWorkshops) { workshop in
                                NavigationLink(destination: WorkshopDetailView(workshop: workshop)) {
                                    FavoriteWorkshopCard(workshop: workshop)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 20)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Favorite Workshop Card Component
struct FavoriteWorkshopCard: View {
    let workshop: Workshop
    @StateObject private var favoriteManager = FavoriteWorkshopManagerVM.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Name and Favorite Button
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workshop.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color("TextPrimary"))
                    
                    if workshop.distance != "-" {
                        Text(workshop.distance)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                FavoriteButtonVM(
                    workshopId: workshop.id.uuidString,
                    favoriteManager: favoriteManager,
                    size: 22,
                    isDarkMode: isDarkMode
                )
            }
            
            // Address
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text(workshop.address)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Rating
            HStack(spacing: 6) {
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(workshop.rating) ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }
                Text(String(format: "%.1f", workshop.rating))
                    .font(.system(size: 13))
                    .foregroundColor(Color("TextPrimary"))
                Text("(\(workshop.reviewCount))")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            // Services Preview
            if !workshop.services.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(workshop.services.prefix(3), id: \.self) { service in
                            Text(service)
                                .font(.system(size: 11))
                                .foregroundColor(Color("AccentNeon"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color("AccentNeon").opacity(0.15))
                                )
                        }
                        if workshop.services.count > 3 {
                            Text("+\(workshop.services.count - 3) more")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color("CardBackground"))
                .shadow(
                    color: isDarkMode ? .clear : .black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        FavoriteWorkshopsView()
            .preferredColorScheme(.dark)
    }
}

#Preview("Light Mode") {
    NavigationStack {
        FavoriteWorkshopsView()
            .preferredColorScheme(.light)
    }
}
