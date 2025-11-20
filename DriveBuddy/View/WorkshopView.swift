//
//  WorkshopView.swift
//  DriveBuddy
//
//  Created by Howie Homan on 04/11/25.
//

import SwiftUI
import CoreLocation

struct WorkshopView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var favoriteManager = FavoriteWorkshopManagerVM.shared
    @State private var searchText = ""
    @State private var selectedFilter: String? = nil
    @State private var workshops: [Workshop] = Workshop.sampleWorkshops
    @State private var sortedWorkshops: [Workshop] = []
    @State private var showLocationAlert = false
    @Environment(\.colorScheme) private var colorScheme
    
    let filters = ["car wash", "oil", "brake", "tire", "engine"]
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background
                Color.black.opacity(0.95).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image("LogoDriveBuddy")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 35)
                            Spacer()
                            
                            // Location status indicator with more info
                            HStack(spacing: 4) {
                                if locationManager.userLocation != nil {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 12))
                                    Text("GPS Active")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.7))
                                } else {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(.white)
                                    Text("Getting location...")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                            )
                            .onTapGesture {
                                if locationManager.userLocation == nil {
                                    showLocationAlert = true
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        Text("Welcome, Jonny")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 15)
                    
                    // MARK: - Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("find a workshop for your next service", text: $searchText)
                            .foregroundColor(.white)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.8))
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 15)
                    
                    // MARK: - Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(filters, id: \.self) { filter in
                                FilterChip(
                                    title: filter,
                                    isSelected: selectedFilter == filter
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedFilter = selectedFilter == filter ? nil : filter
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 15)
                    
                    // MARK: - Workshop List
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 15) {
                            ForEach(filteredAndSortedWorkshops) { workshop in
                                NavigationLink(destination: WorkshopDetailView(workshop: workshop)) {
                                    WorkshopCard(
                                        workshop: workshop,
                                        favoriteManager: favoriteManager,
                                        isDarkMode: isDarkMode
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                locationManager.requestPermission()
                updateWorkshopDistances()
            }
            .onChange(of: locationManager.userLocation) { oldValue, newValue in
                // Only update if location actually changed and is not nil
                guard let newLocation = newValue else { return }
                
                // Check if coordinates actually changed
                if let oldLocation = oldValue {
                    let latChanged = abs(oldLocation.coordinate.latitude - newLocation.coordinate.latitude) > 0.0001
                    let lonChanged = abs(oldLocation.coordinate.longitude - newLocation.coordinate.longitude) > 0.0001
                    
                    if latChanged || lonChanged {
                        updateWorkshopDistances()
                    }
                } else {
                    // First time getting location
                    updateWorkshopDistances()
                }
            }
            .alert("Location Permission Required", isPresented: $showLocationAlert) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable location access to see distances to workshops.")
            }
        }
    }
    
    // MARK: - Filter and Sort Workshops
    var filteredAndSortedWorkshops: [Workshop] {
        var result = sortedWorkshops.isEmpty ? workshops : sortedWorkshops
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { workshop in
                workshop.name.localizedCaseInsensitiveContains(searchText) ||
                workshop.address.localizedCaseInsensitiveContains(searchText) ||
                workshop.services.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Filter by selected service
        if let filter = selectedFilter {
            result = result.filter { workshop in
                workshop.services.contains { service in
                    service.localizedCaseInsensitiveContains(filter)
                }
            }
        }
        
        return result
    }
    
    // MARK: - Update Workshop Distances
    func updateWorkshopDistances() {
        // Prevent multiple simultaneous updates
        guard locationManager.userLocation != nil else {
            print("⚠️ User location not available yet")
            return
        }
        
        print("🔍 Updating distances...")
        print("📍 User location: \(locationManager.userLocation?.coordinate.latitude ?? 0), \(locationManager.userLocation?.coordinate.longitude ?? 0)")
        
        var updatedWorkshops = workshops
        
        for index in updatedWorkshops.indices {
            let distance = locationManager.calculateDistance(to: updatedWorkshops[index].coordinate)
            let distanceMeters = locationManager.distanceInMeters(to: updatedWorkshops[index].coordinate)
            
            updatedWorkshops[index].distance = distance
            updatedWorkshops[index].distanceInMeters = distanceMeters
            
            print("🏪 \(updatedWorkshops[index].name): \(distance)")
        }
        
        // Sort by distance (nearest first)
        sortedWorkshops = updatedWorkshops.sorted { workshop1, workshop2 in
            guard let dist1 = workshop1.distanceInMeters,
                  let dist2 = workshop2.distanceInMeters else {
                return false
            }
            return dist1 < dist2
        }
        
        workshops = updatedWorkshops
        print("✅ Distance update completed!")
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconForFilter(title))
                    .font(.system(size: 14))
                Text(title)
                    .font(.subheadline)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue.opacity(0.6) : Color.white.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.blue : Color.white.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private func iconForFilter(_ filter: String) -> String {
        switch filter {
        case "car wash": return "car"
        case "oil": return "drop.fill"
        case "brake": return "pedal.brake"
        case "tire": return "circle.circle"
        case "engine": return "engine.combustion"
        default: return "wrench"
        }
    }
}

// MARK: - Workshop Card Component
struct WorkshopCard: View {
    let workshop: Workshop
    @ObservedObject var favoriteManager: FavoriteWorkshopManagerVM
    let isDarkMode: Bool
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Workshop Name with Distance Badge and Favorite Button
            HStack(alignment: .top) {
                Text(workshop.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 12) {
                    if workshop.distance != "-" {
                        Text(workshop.distance)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.6))
                            )
                    }
                    
                    // 🆕 Favorite Button
                    FavoriteButtonVM(
                        workshopId: workshop.id.uuidString,
                        favoriteManager: favoriteManager,
                        size: 20,
                        isDarkMode: true
                    )
                }
            }
            
            // MARK: - Address
            HStack(alignment: .top, spacing: 6) {
                Text("Address:")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 70, alignment: .leading)
                Text(workshop.address)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.system(size: 13))
            
            // MARK: - Open Hours with Dropdown
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Text("Open Hours:")
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 70, alignment: .leading)
                    Text(workshop.openHours)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .font(.system(size: 12))
                }
                .font(.system(size: 13))
            }
            
            // MARK: - Rating
            HStack(spacing: 6) {
                Text("Rating:")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 70, alignment: .leading)
                HStack(spacing: 2) {
                    Text(String(format: "%.1f", workshop.rating))
                        .foregroundColor(.white)
                    HStack(spacing: 1) {
                        ForEach(0..<5) { index in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                    }
                    Text("(\(workshop.reviewCount))")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .font(.system(size: 13))
            
            // MARK: - Available Services
            if !workshop.services.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available Services:")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 13))
                    
                    Text(workshop.services.joined(separator: ", "))
                        .foregroundColor(.white)
                        .font(.system(size: 13))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.blue.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    WorkshopView()
}
