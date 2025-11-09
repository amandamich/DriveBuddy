//
//  MyServiceView.swift
//  DriveBuddy
//
//  Created by Antonius Trimaryono on 09/11/25.
//

import SwiftUI

struct MyServiceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text("My Service")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Spacer().frame(width: 24)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    Spacer(minLength: 5)
                    
                    // MARK: Ongoing Service
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ongoing Service")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        ServiceCard(
                            title: "Tire Rotation",
                            date: "25 December 2025",
                            detail: "50,000 km | Next : 70,000 km",
                            type: .upcoming
                        )
                    }
                    .padding(.horizontal)
                    
                    // MARK: Last Service
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last Service")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        ServiceCard(
                            title: "Oil Change",
                            date: "2 November 2025",
                            detail: "45,000 km | Next : 60,000 km\nBengkel Haris Mobil Surabaya\nNotes: Changes Oil and filter",
                            type: .completed
                        )
                        
                        ServiceCard(
                            title: "Engine",
                            date: "7 July 2025",
                            detail: "45,000 km | Next : 60,000 km\nBengkel Jaya Anda Surabaya\nNotes: System Rem",
                            type: .completed
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
                .padding(.bottom, 80)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Enum untuk Status Type
enum ServiceType {
    case upcoming
    case completed
    
    var title: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .completed: return "Completed"
        }
    }
    
    var color: Color {
        switch self {
        case .upcoming: return Color.orange
        case .completed: return Color.green
        }
    }
}

// MARK: - Service Card Component
struct ServiceCard: View {
    var title: String
    var date: String
    var detail: String
    var type: ServiceType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(4)
                        .padding(.top, 2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(date)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    // Status sejajar bawah
                    Text(type.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(type.color)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .frame(alignment: .bottomTrailing)
            }
        }
        .padding()
        .background(Color(red: 17/255, green: 33/255, blue: 66/255))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 4)
    }
}

#Preview {
    MyServiceView()
}
