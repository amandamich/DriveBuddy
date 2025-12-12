//
//  TaxHistoryView.swift
//  DriveBuddy
//
//  Created by Timothy on 26/11/25.
//

import SwiftUI

struct TaxHistoryView: View {
    @StateObject private var taxManager = TaxHistoryVM.shared
    @State private var showAddTaxSheet = false
    @State private var selectedFilter: TaxFilter = .all
    
    let vehicle: Vehicle // Current vehicle to filter by
    
    enum TaxFilter: String, CaseIterable {
        case all = "All"
        case valid = "Valid"
        case expiring = "Expiring"
        case expired = "Expired"
    }
    
    // Filter taxes by current vehicle's license plate
    var vehicleTaxes: [TaxModel] {
        return taxManager.taxHistories.filter { $0.vehiclePlate == vehicle.licensePlate }
    }
    
    var filteredTaxes: [TaxModel] {
        switch selectedFilter {
        case .all:
            return vehicleTaxes
        case .valid:
            return vehicleTaxes.filter { $0.status == .valid }
        case .expiring:
            return vehicleTaxes.filter { $0.status == .expiringSoon }
        case .expired:
            return vehicleTaxes.filter { $0.status == .expired }
        }
    }
    
    var expiredCount: Int {
        vehicleTaxes.filter { $0.status == .expired }.count
    }
    
    var expiringCount: Int {
        vehicleTaxes.filter { $0.status == .expiringSoon }.count
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tax History")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        Text(vehicle.licensePlate)
                            .font(.system(size: 15))
                            .foregroundColor(.cyan)
                    }
                    Spacer()
                    
                    // Add Button
                    Button(action: {
                        showAddTaxSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.cyan)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Alert Cards (Blue background)
                if expiredCount > 0 || expiringCount > 0 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            if expiredCount > 0 {
                                AlertCardBlue(
                                    icon: "exclamationmark.triangle.fill",
                                    title: "Expired",
                                    count: expiredCount,
                                    color: .red
                                )
                            }
                            
                            if expiringCount > 0 {
                                AlertCardBlue(
                                    icon: "clock.fill",
                                    title: "Expiring Soon",
                                    count: expiringCount,
                                    color: .orange
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 16)
                }
                
                // Filter Tabs (Blue when selected)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TaxFilter.allCases, id: \.self) { filter in
                            FilterTabBlue(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                withAnimation {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)
                
                // Tax List
                if filteredTaxes.isEmpty {
                    EmptyStateTaxView(filter: selectedFilter, vehiclePlate: vehicle.licensePlate)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(filteredTaxes) { tax in
                                NavigationLink(destination: TaxDetailView(tax: tax)) {
                                    TaxHistoryCardBlue(tax: tax)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showAddTaxSheet) {
            AddTaxView(vehicle: vehicle) // Pass current vehicle
        }
        .onAppear {
            taxManager.loadTaxHistories() // Refresh when view appears
        }
    }
}

// MARK: - Alert Card (Blue style)
struct AlertCardBlue: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Filter Tab (Blue when selected)
struct FilterTabBlue: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(white: 0.15))
                )
        }
    }
}

// MARK: - Tax History Card (Blue accents)
struct TaxHistoryCardBlue: View {
    let tax: TaxModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Vehicle Icon with Status
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.cyan)
                
                // Status Badge
                Circle()
                    .fill(statusColor(for: tax.status))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .offset(x: 4, y: 4)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(tax.formattedAmount)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(tax.location)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text("Valid until: \(tax.validUntil, format: .dateTime.day().month().year())")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Status & Arrow
            VStack(alignment: .trailing, spacing: 8) {
                StatusBadge(status: tax.status)
                
                if tax.status == .expiringSoon {
                    Text("\(tax.daysUntilExpiry) days")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.blue.opacity(0.15))
        )
    }
    
    func statusColor(for status: TaxStatus) -> Color {
        switch status {
        case .valid: return .green
        case .expiringSoon: return .orange
        case .expired: return .red
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: TaxStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor)
            )
    }
    
    var statusColor: Color {
        switch status {
        case .valid: return .green
        case .expiringSoon: return .orange
        case .expired: return .red
        }
    }
}

// MARK: - Empty State
struct EmptyStateTaxView: View {
    let filter: TaxHistoryView.TaxFilter
    let vehiclePlate: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No \(filter.rawValue) Tax Records")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Add tax payment history for \(vehiclePlate)")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
