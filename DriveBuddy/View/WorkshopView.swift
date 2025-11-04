//
//  WorkshopView.swift
//  DriveBuddy
//
//  Created by Howie Homan on 04/11/25.
//

import SwiftUI

struct WorkshopView: View {
    @State private var searchText = ""
    @State private var selectedFilter: String? = nil
    
    let filters = ["car wash", "oil", "brake", "tire", "engine"]
    
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
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
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
                            WorkshopCard(
                                name: "Bengkel Harris Mobil Surabaya",
                                address: "Jl. Raya Kendangsari No.21, Kendangsari, Kec. Tenggilis Mejoyo",
                                distance: "-",
                                openHours: "Monday, 08:30am - 17:00pm",
                                rating: 4.9,
                                reviewCount: 1613,
                                services: ["AC Car", "Spooring Balancing", "Tune Up", "Oil Change and Matic"]
                            )
                            
                            WorkshopCard(
                                name: "Bengkel Jaya Anda Surabaya",
                                address: "Jl. Ngagel Tim. No.25, Pucang Sewu, Kec. Gubeng",
                                distance: "-",
                                openHours: "Monday, 08:00am - 17:00pm",
                                rating: 4.9,
                                reviewCount: 2955,
                                services: ["Specialist onderstel / understelsel"]
                            )
                            
                            WorkshopCard(
                                name: "Mobeng Jemusari",
                                address: "Jl. Raya Jemusari No.190, Kendangsari, Kec. Tenggilis Mejoyo",
                                distance: "-",
                                openHours: "Monday, 09:00am - 21:00pm",
                                rating: 4.6,
                                reviewCount: 519,
                                services: ["Oil Change", "Spare parts"]
                            )
                            
                            WorkshopCard(
                                name: "FT Garage",
                                address: "Jl. Raya Kedung Asem No.99, Kedung Baruk, Kec. Rungkut",
                                distance: "-",
                                openHours: "Monday, 08:30am - 17:00pm",
                                rating: 4.9,
                                reviewCount: 0,
                                services: []
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
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
        case "brake": return "brake.signal"
        case "tire": return "circle.circle"
        case "engine": return "engine.combustion"
        default: return "wrench"
        }
    }
}

// MARK: - Workshop Card Component
struct WorkshopCard: View {
    let name: String
    let address: String
    let distance: String
    let openHours: String
    let rating: Double
    let reviewCount: Int
    let services: [String]
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Workshop Name
            Text(name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            // MARK: - Address
            HStack(alignment: .top, spacing: 6) {
                Text("Address:")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 70, alignment: .leading)
                Text(address)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.system(size: 13))
            
            // MARK: - Distance
            HStack(spacing: 6) {
                Text("Distance:")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 70, alignment: .leading)
                Text(distance)
                    .foregroundColor(.white)
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
                    Text(openHours)
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
                    Text(String(format: "%.1f", rating))
                        .foregroundColor(.white)
                    HStack(spacing: 1) {
                        ForEach(0..<5) { index in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                    }
                    Text("(\(reviewCount))")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .font(.system(size: 13))
            
            // MARK: - Available Services
            if !services.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available Services:")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 13))
                    
                    Text(services.joined(separator: ", "))
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
