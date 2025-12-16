//
//  WorkshopView.swift
//  DriveBuddy
//
//  Created by Howie Homan on 04/11/25.
//

import SwiftUI
import CoreLocation

// MARK: - Daily Schedule Model
struct DailySchedule: Identifiable {
    let id = UUID()
    let day: String
    let hours: String
    let isOpen: Bool
}

// MARK: - Main Workshop View
struct WorkshopView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var favoriteManager = FavoriteWorkshopManagerVM.shared
    @State private var searchText = ""
    @State private var selectedFilters: Set<String> = []
    @State private var workshops: [Workshop] = Workshop.sampleWorkshops
    @State private var sortedWorkshops: [Workshop] = []
    @State private var showLocationAlert = false
    @Environment(\.colorScheme) private var colorScheme
    
    let filters = ["Car Wash", "Oil", "Brake", "Tire", "Engine"]
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    // MARK: - Fixed Location (Universitas Ciputra)
        private let universityCiputraLocation = CLLocation(
            latitude: -7.2865722,
            longitude: 112.6320953
        )
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background
                Color.black.opacity(0.95).ignoresSafeArea()
                
                mainContentView
            }
            .navigationBarHidden(true)
            .onAppear {
                print("🎬 WorkshopView appeared")
                locationManager.requestPermission()
                
                // If location already available, update immediately
                if locationManager.userLocation != nil {
                    print("✅ Location already available on appear")
                    updateWorkshopDistances()
                }
            }
            .onChange(of: locationManager.userLocation) { oldValue, newValue in
                print("🔄 Location changed - Old: \(oldValue?.coordinate.latitude ?? 0), New: \(newValue?.coordinate.latitude ?? 0)")
                
                // Update whenever location changes
                if newValue != nil {
                    print("✅ New location available, updating distances...")
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

    // MARK: - Main Content View
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            headerView
            
            // MARK: - Search Bar
            searchBarView
            
            // MARK: - Filter Chips
            filterChipsView
            
            // MARK: - Workshop List
            workshopListView
        }
    }

    // MARK: - Header View
    private var headerView: some View {
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
    }

    // MARK: - Search Bar View
    private var searchBarView: some View {
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
    }

    // MARK: - Filter Chips View
    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(filters, id: \.self) { filter in
                    FilterChip(
                        title: filter,
                        isSelected: selectedFilters.contains(filter)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedFilters.contains(filter) {
                                selectedFilters.remove(filter)
                            } else {
                                selectedFilters.insert(filter)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 15)
    }

    // MARK: - Workshop List View
    private var workshopListView: some View {
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
        if !selectedFilters.isEmpty {
            result = result.filter { workshop in
                selectedFilters.contains { filter in
                    workshop.services.contains { service in
                        service.localizedCaseInsensitiveContains(filter)
                    }
                }
            }
        }
        
        return result
    }
    
   
    // MARK: - Update Workshop Distances
    func updateWorkshopDistances() {
        print("🔍 Calculating distances from Universitas Ciputra...")
        
        var updatedWorkshops = workshops
        
        for index in updatedWorkshops.indices {
            let workshop = updatedWorkshops[index]
            
            // Create CLLocation for workshop
            let workshopLocation = CLLocation(
                latitude: workshop.coordinate.latitude,
                longitude: workshop.coordinate.longitude
            )
            
            // Calculate distance
            let distanceInMeters = universityCiputraLocation.distance(from: workshopLocation)
            
            // Format distance
            let distance: String
            if distanceInMeters < 1000 {
                distance = String(format: "%.0f m", distanceInMeters)
            } else {
                distance = String(format: "%.1f km", distanceInMeters / 1000)
            }
            
            updatedWorkshops[index].distance = distance
            updatedWorkshops[index].distanceInMeters = distanceInMeters
            
            print("🏪 \(workshop.name): \(distance)")
        }
        
        // Sort by distance
        sortedWorkshops = updatedWorkshops.sorted {
            ($0.distanceInMeters ?? Double.greatestFiniteMagnitude) <
            ($1.distanceInMeters ?? Double.greatestFiniteMagnitude)
        }
        
        workshops = updatedWorkshops
        print("✅ Distance calculation completed!")
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
    
    // Get real schedule based on workshop name from Google Maps
    private var weeklySchedule: [DailySchedule] {
        switch workshop.name {
        case "Bengkel Harris Mobil Surabaya":
            return [
                DailySchedule(day: "Monday", hours: "08:30 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Tuesday", hours: "08:30 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Wednesday", hours: "08:30 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Thursday", hours: "08:30 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Friday", hours: "08:30 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Saturday", hours: "08:00 AM - 03:30 PM", isOpen: true),
                DailySchedule(day: "Sunday", hours: "Closed", isOpen: false)
            ]
            
        case "Bengkel Jaya Anda Surabaya":
            return [
                DailySchedule(day: "Monday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Tuesday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Wednesday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Thursday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Friday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Saturday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Sunday", hours: "Closed", isOpen: false)
            ]
            
        case "Mobeng Jemusari":
            return [
                DailySchedule(day: "Monday", hours: "09:00 AM - 09:00 PM", isOpen: true),
                DailySchedule(day: "Tuesday", hours: "09:00 AM - 09:00 PM", isOpen: true),
                DailySchedule(day: "Wednesday", hours: "09:00 AM - 09:00 PM", isOpen: true),
                DailySchedule(day: "Thursday", hours: "09:00 AM - 09:00 PM", isOpen: true),
                DailySchedule(day: "Friday", hours: "09:00 AM - 09:00 PM", isOpen: true),
                DailySchedule(day: "Saturday", hours: "09:00 AM - 09:00 PM", isOpen: true),
                DailySchedule(day: "Sunday", hours: "09:00 AM - 09:00 PM", isOpen: true)
            ]
            
        case "FT Garage":
            return [
                DailySchedule(day: "Monday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Tuesday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Wednesday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Thursday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Friday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Saturday", hours: "08:00 AM - 04:00 PM", isOpen: true),
                DailySchedule(day: "Sunday", hours: "Closed", isOpen: false)
            ]
            
        case "Bengkel Mobil 88":
            return [
                DailySchedule(day: "Monday", hours: "08:00 AM - 06:00 PM", isOpen: true),
                DailySchedule(day: "Tuesday", hours: "08:00 AM - 06:00 PM", isOpen: true),
                DailySchedule(day: "Wednesday", hours: "08:00 AM - 06:00 PM", isOpen: true),
                DailySchedule(day: "Thursday", hours: "08:00 AM - 06:00 PM", isOpen: true),
                DailySchedule(day: "Friday", hours: "08:00 AM - 06:00 PM", isOpen: true),
                DailySchedule(day: "Saturday", hours: "08:00 AM - 06:00 PM", isOpen: true),
                DailySchedule(day: "Sunday", hours: "Closed", isOpen: false)
            ]
            
        case "Auto Care Plus":
            return [
                DailySchedule(day: "Monday", hours: "09:00 AM - 08:00 PM", isOpen: true),
                DailySchedule(day: "Tuesday", hours: "09:00 AM - 08:00 PM", isOpen: true),
                DailySchedule(day: "Wednesday", hours: "09:00 AM - 08:00 PM", isOpen: true),
                DailySchedule(day: "Thursday", hours: "09:00 AM - 08:00 PM", isOpen: true),
                DailySchedule(day: "Friday", hours: "09:00 AM - 08:00 PM", isOpen: true),
                DailySchedule(day: "Saturday", hours: "09:00 AM - 08:00 PM", isOpen: true),
                DailySchedule(day: "Sunday", hours: "09:00 AM - 08:00 PM", isOpen: true)
            ]
            
        case "Bengkel Resmi Honda":
            return [
                DailySchedule(day: "Monday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Tuesday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Wednesday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Thursday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Friday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Saturday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                DailySchedule(day: "Sunday", hours: "Closed", isOpen: false)
            ]
            
        case "Tire Master Surabaya":
            return [
                DailySchedule(day: "Monday", hours: "08:30 AM - 06:00 PM", isOpen: true),
                DailySchedule(day: "Tuesday", hours: "08:30 AM - 06:00 PM", isOpen: true),
                DailySchedule(day: "Wednesday", hours: "08:30 AM - 06:00 PM", isOpen: true),
                DailySchedule(day: "Thursday", hours: "08:30 AM - 06:00 PM", isOpen: true),
                DailySchedule(day: "Friday", hours: "08:30 AM - 06:00 PM", isOpen: true),
                DailySchedule(day: "Saturday", hours: "08:30 AM - 06:00 PM", isOpen: true),
                DailySchedule(day: "Sunday", hours: "Closed", isOpen: false)
            ]
            
            case "Bengkel Mobil Karya Abadi":
                return [
                    DailySchedule(day: "Monday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Tuesday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Wednesday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Thursday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Friday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Saturday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Sunday", hours: "Open 24 hours", isOpen: true)
                ]

            case "Jaya Anda Workshop - Car Suspension Specialist":
                return [
                    DailySchedule(day: "Monday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                    DailySchedule(day: "Tuesday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                    DailySchedule(day: "Wednesday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                    DailySchedule(day: "Thursday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                    DailySchedule(day: "Friday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                    DailySchedule(day: "Saturday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                    DailySchedule(day: "Sunday", hours: "Closed", isOpen: false)
                ]

            case "Bengkel Metropolis":
                return [
                    DailySchedule(day: "Monday", hours: "08:00 AM - 06:00 PM", isOpen: true),
                    DailySchedule(day: "Tuesday", hours: "08:00 AM - 06:00 PM", isOpen: true),
                    DailySchedule(day: "Wednesday", hours: "08:00 AM - 06:00 PM", isOpen: true),
                    DailySchedule(day: "Thursday", hours: "08:00 AM - 06:00 PM", isOpen: true),
                    DailySchedule(day: "Friday", hours: "08:00 AM - 06:00 PM", isOpen: true),
                    DailySchedule(day: "Saturday", hours: "08:00 AM - 06:00 PM", isOpen: true),
                    DailySchedule(day: "Sunday", hours: "Closed", isOpen: false)
                ]

            case "Bengkel Dunia Mobil Surabaya":
                return [
                    DailySchedule(day: "Monday", hours: "08:00 AM - 04:30 PM", isOpen: true),
                    DailySchedule(day: "Tuesday", hours: "08:00 AM - 04:30 PM", isOpen: true),
                    DailySchedule(day: "Wednesday", hours: "08:00 AM - 04:30 PM", isOpen: true),
                    DailySchedule(day: "Thursday", hours: "08:00 AM - 04:30 PM", isOpen: true),
                    DailySchedule(day: "Friday", hours: "08:00 AM - 04:30 PM", isOpen: true),
                    DailySchedule(day: "Saturday", hours: "08:00 AM - 04:30 PM", isOpen: true),
                    DailySchedule(day: "Sunday", hours: "Closed", isOpen: false)
                ]

            case "Bengkel Mobil FT Garage Kedung Asem":
                return [
                    DailySchedule(day: "Monday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                    DailySchedule(day: "Tuesday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                    DailySchedule(day: "Wednesday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                    DailySchedule(day: "Thursday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                    DailySchedule(day: "Friday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                    DailySchedule(day: "Saturday", hours: "08:00 AM - 05:00 PM", isOpen: true),
                    DailySchedule(day: "Sunday", hours: "Closed", isOpen: false)
                ]

            case "Bengkel Panggilan Noviant Remaap ECU":
                return [
                    DailySchedule(day: "Monday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Tuesday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Wednesday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Thursday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Friday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Saturday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Sunday", hours: "Open 24 hours", isOpen: true)
                ]

        default:
            // Default schedule for any other workshops
                return [
                    DailySchedule(day: "Monday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Tuesday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Wednesday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Thursday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Friday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Saturday", hours: "Open 24 hours", isOpen: true),
                    DailySchedule(day: "Sunday", hours: "Open 24 hours", isOpen: true)
                ]
        }
    }
    
    // Get today's schedule
    private var todaySchedule: DailySchedule? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let today = formatter.string(from: Date())
        return weeklySchedule.first { $0.day == today }
    }
    
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
                    
                    // Favorite Button
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
            
            // MARK: - Open Hours with Dropdown Schedule
            VStack(alignment: .leading, spacing: 8) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text("Open Hours:")
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 70, alignment: .leading)
                        
                        // Show current day's hours or summary
                        if let today = todaySchedule {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(today.isOpen ? Color.green : Color.red)
                                    .frame(width: 6, height: 6)
                                Text(today.isOpen ? today.hours : "Closed today")
                                    .foregroundColor(.white)
                            }
                        } else {
                            Text(workshop.openHours)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white.opacity(0.7))
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .font(.system(size: 12))
                    }
                    .font(.system(size: 13))
                }
                
                // MARK: - Expanded Schedule
                if isExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(weeklySchedule) { dailySchedule in
                            HStack {
                                Text(dailySchedule.day)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 80, alignment: .leading)
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(dailySchedule.isOpen ? Color.green.opacity(0.8) : Color.red.opacity(0.8))
                                        .frame(width: 5, height: 5)
                                    
                                    Text(dailySchedule.hours)
                                        .font(.system(size: 12))
                                        .foregroundColor(dailySchedule.isOpen ? .white : .white.opacity(0.5))
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 2)
                            .padding(.leading, 76)
                        }
                    }
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
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

// MARK: - Preview
#Preview {
    WorkshopView()
}
