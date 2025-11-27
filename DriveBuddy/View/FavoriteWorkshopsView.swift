//
//  FavoriteWorkshopsView.swift
//  DriveBuddy
//
//  View for displaying all favorite workshops
//

import SwiftUI

struct FavoriteWorkshopsView: View {
    @StateObject private var favoriteManager = FavoriteWorkshopManagerVM.shared
    
    // Get all workshops from sample data
    private var allWorkshops: [Workshop] {
        Workshop.sampleWorkshops
    }
    
    private var favoriteWorkshops: [Workshop] {
        favoriteManager.getFavoriteWorkshops(from: allWorkshops)
    }
    
    var body: some View {
        ZStack {
            // Background - Pure dark like your app
            Color.black.opacity(0.95).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Custom Header with Logo
                VStack(spacing: 12) {
                    HStack {
                        Image("LogoDriveBuddy")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 35)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    Text("Favorite Workshops")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
                
                // Content
                if favoriteWorkshops.isEmpty {
                    // Empty State
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(systemName: "heart.slash")
                            .font(.system(size: 70, weight: .thin))
                            .foregroundColor(.gray.opacity(0.4))
                        
                        VStack(spacing: 8) {
                            Text("No Favorite Workshops Yet")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Start adding workshops to your favorites\nby tapping the heart icon")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 40)
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
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Favorite Workshop Card Component
struct FavoriteWorkshopCard: View {
    let workshop: Workshop
    @StateObject private var favoriteManager = FavoriteWorkshopManagerVM.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Name and Favorite Button
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(workshop.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
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
                    isDarkMode: true
                )
            }
            
            // Address
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.cyan)
                
                Text(workshop.address)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Open Hours
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.cyan)
                
                Text(workshop.openHours)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            // Rating
            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(workshop.rating) ? "star.fill" : "star")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                    }
                }
                Text(String(format: "%.1f", workshop.rating))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                Text("(\(workshop.reviewCount))")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            // Services Preview
            if !workshop.services.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Services:")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(workshop.services.prefix(4), id: \.self) { service in
                                Text(service)
                                    .font(.system(size: 11))
                                    .foregroundColor(.cyan)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                                            .background(
                                                Capsule()
                                                    .fill(Color.cyan.opacity(0.1))
                                            )
                                    )
                            }
                            if workshop.services.count > 4 {
                                Text("+\(workshop.services.count - 4)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.blue.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        FavoriteWorkshopsView()
            .preferredColorScheme(.dark)
    }
}
