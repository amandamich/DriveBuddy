//
//  WorkshopDetailView.swift
//  DriveBuddy
//
//  Detail view untuk workshop yang dipilih
//  Menampilkan informasi lengkap dan map location
//

import SwiftUI
import MapKit

struct WorkshopDetailView: View {
    let workshop: Workshop
    @StateObject private var favoriteManager = FavoriteWorkshopManagerVM.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var region: MKCoordinateRegion
    @State private var showDirections = false
    @State private var selectedDay = "Monday"
    
    let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    init(workshop: Workshop) {
        self.workshop = workshop
        _region = State(initialValue: MKCoordinateRegion(
            center: workshop.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // MARK: - Map View
                    ZStack(alignment: .topTrailing) {
                        Map(coordinateRegion: $region, annotationItems: [workshop]) { workshop in
                            MapMarker(coordinate: workshop.coordinate, tint: .red)
                        }
                        .frame(height: 250)
                        .cornerRadius(0)
                        
                        // Top Bar with Favorite Button only
                        VStack {
                            // Favorite Button - moved higher
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    favoriteManager.toggleFavorite(workshopId: workshop.id.uuidString)
                                }
                            }) {
                                Image(systemName: favoriteManager.isFavorite(workshopId: workshop.id.uuidString) ? "heart.fill" : "heart")
                                    .font(.system(size: 22))
                                    .foregroundColor(favoriteManager.isFavorite(workshopId: workshop.id.uuidString) ? .red : .white)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.6))
                                            .shadow(radius: 5)
                                    )
                                    .scaleEffect(favoriteManager.isFavorite(workshopId: workshop.id.uuidString) ? 1.1 : 1.0)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    
                    // MARK: - Content
                    VStack(alignment: .leading, spacing: 20) {
                        // Workshop Name & Distance
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(workshop.name)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                // Rating
                                HStack(spacing: 8) {
                                    HStack(spacing: 2) {
                                        ForEach(0..<5) { index in
                                            Image(systemName: index < Int(workshop.rating) ? "star.fill" : "star")
                                                .font(.system(size: 14))
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    Text(String(format: "%.1f", workshop.rating))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("(\(workshop.reviewCount) reviews)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            
                            Spacer()
                            
                            // Distance Badge
                            if workshop.distance != "-" {
                                VStack(spacing: 4) {
                                    Text(workshop.distance)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("away")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.green.opacity(0.6))
                                )
                            }
                        }
                        .padding(.top, 20)
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        // MARK: - Address Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label {
                                Text("Address")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.cyan)
                            } icon: {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.cyan)
                            }
                            
                            Text(workshop.address)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                        
                        // MARK: - Open Hours Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label {
                                Text("Opening Hours")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.cyan)
                            } icon: {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.cyan)
                            }
                            
                            Text(workshop.openHours)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.9))
                            
                            // Status badge
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Open Now")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                        
                        // MARK: - Services Section
                        if !workshop.services.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label {
                                    Text("Available Services")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.cyan)
                                } icon: {
                                    Image(systemName: "wrench.and.screwdriver.fill")
                                        .foregroundColor(.cyan)
                                }
                                
                                FlowLayout(spacing: 8) {
                                    ForEach(workshop.services, id: \.self) { service in
                                        Text(service)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(Color.blue.opacity(0.3))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 20)
                                                            .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                                    )
                                            )
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            )
                        }
                        
                        // MARK: - Action Buttons
                        VStack(alignment: .center, spacing: 15) {
                            // Get Directions Button
                            Button(action: {
                                openInMaps()
                            }) {
                                HStack {
                                    Image(systemName: "map.fill")
                                        .font(.system(size: 18))
                                    Text("Get Directions")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 370)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.cyan, lineWidth: 2)
                                        .shadow(color: .blue, radius: 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.black.opacity(0.5))
                                        )
                                )
                                .shadow(color: .blue, radius: 10)
                            }
                            
                            // Call Button
                            Button(action: {
                                openWhatsApp()
                            }) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 18))
                                    Text("Contact Workshop")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 370)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 2)
                                        .shadow(color: .blue, radius: 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.black.opacity(0.5))
                                        )
                                )
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(.cyan) // This makes the back button cyan/blue
    }
    
    // MARK: - Open in Maps
    func openInMaps() {
        let coordinate = workshop.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = workshop.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    // MARK: - Open WhatsApp
    func openWhatsApp() {
        // Pre-filled message
        let message = "Hello! I found your workshop '\(workshop.name)' on DriveBuddy app. I would like to inquire about your services."
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
        
        let phoneNumber = workshop.phoneNumber
        
        // Try WhatsApp app first, then fallback to web WhatsApp
        let whatsappURL = "whatsapp://send?phone=\(phoneNumber)&text=\(encodedMessage)"
        let whatsappWebURL = "https://wa.me/\(phoneNumber)?text=\(encodedMessage)"
        
        if let url = URL(string: whatsappURL), UIApplication.shared.canOpenURL(url) {
            // WhatsApp app installed
            UIApplication.shared.open(url)
        } else if let webURL = URL(string: whatsappWebURL) {
            // Fallback to web WhatsApp
            UIApplication.shared.open(webURL)
        }
    }
}

// MARK: - Flow Layout for Services Tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var frames: [CGRect]
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var frames: [CGRect] = []
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.frames = frames
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    NavigationStack {
        WorkshopDetailView(workshop: Workshop.sampleWorkshops[0])
    }
}
