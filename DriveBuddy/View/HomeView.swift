//
//  HomeView.swift
//  DriveBuddy
//
//  Created by Timothy on 28/10/25.
//

import SwiftUI
import CoreData
struct HomeView: View {
	@ObservedObject var authVM: AuthenticationViewModel
	
	@State private var selectedTab: Int = 0
	
	var body: some View {
		// Custom Tab Bar
//				HStack {
//					Spacer()
//					Button(action: { selectedTab = 0 }) {
//						VStack {
//							Image(systemName: "house.fill")
//								.font(.system(size: 20))
//								.foregroundColor(selectedTab == 0 ? .white : .white.opacity(0.6))
//								.padding(12)
//								.background(
//									Circle()
//										.fill(selectedTab == 0 ? Color.blue : Color.clear)
//								)
//						}
//					}
//					Spacer()
//
//					Button(action: { selectedTab = 1 }) {
//						Image(systemName: "wrench.and.screwdriver.fill")
//							.font(.system(size: 20))
//							.foregroundColor(selectedTab == 1 ? .white : .white.opacity(0.6))
//					}
//					Spacer()
//
//					Button(action: { selectedTab = 2 }) {
//						Image(systemName: "person.circle")
//							.font(.system(size: 20))
//							.foregroundColor(selectedTab == 2 ? .white : .white.opacity(0.6))
//					}
//					Spacer()
//				}
//				.frame(height: 70)
//				.background(
//					RoundedRectangle(cornerRadius: 12)
//							  .stroke(Color.cyan, lineWidth: 2)
//							  .shadow(color: .blue, radius: 8)
//							  .background(
//							  RoundedRectangle(cornerRadius: 12)
//							  .fill(Color.black.opacity(0.5)))
//					  )
//					  .shadow(color: .blue, radius: 10)
//				.clipShape(RoundedRectangle(cornerRadius: 20))
//				.padding(.horizontal, 0)
		
		//Bottom Tab Bar
		TabView{
				DashboardView()
					.tabItem{
						Label("Home", systemImage: "house")
					}

			VehicleView()
				.tabItem{
					Label("Vehicle", systemImage: "gauge.with.dots.needle.67percent")
				}
			WorkshopsView()
				.tabItem{
					Label("Workshops", systemImage:"wrench.and.screwdriver.fill")
				}
			ProfileView()
				.tabItem{
					Label("Profile", systemImage:"person")
				}
			
		}
		.tint(.blue)
		
	}
}
struct DashboardView:View {
	var body: some View {
		ZStack {
			Color.black.opacity(0.95)
				.ignoresSafeArea()
			
			VStack(alignment: .leading, spacing: 30) {
				// Header
				VStack(alignment: .leading, spacing: 0) {
					Image("LogoDriveBuddy")
						.resizable()
						.scaledToFit()
						.frame(width: 200, height: 50)
						.foregroundColor(.white)
					
					
						Text("Welcome (User)")
						.font(.headline)
							.foregroundColor(.white.opacity(0.8))
					
				}
				.padding(.top, 20)
				.padding(.horizontal, 20)
				
				// Add Vehicle Button
				Button(action: {
					withAnimation(.easeInOut(duration: 0.3)) {
						
					}
				}) {
					Text("+ Add Vehicle")
						.font(.headline)
						.foregroundColor(.white)
						.padding()
						.frame(maxWidth: .infinity, maxHeight: 150)
						.background(
							RoundedRectangle(cornerRadius: 12)
								.stroke(Color.cyan, lineWidth: 2)
								.shadow(color: .blue, radius: 8)
								.background(
								RoundedRectangle(cornerRadius: 12)
								.fill(Color.black.opacity(0.5)))
						)
						.shadow(color: .blue, radius: 10)
				}
				.padding(.horizontal, 20)
				
				Spacer()
				
				
			}
			
			
		}
		.ignoresSafeArea(edges: .bottom)
	}
}
struct VehicleView:View {
	var body: some View {
		VStack{
			Text("👀 VEHICLE")
				.font(.largeTitle)
		}
	}
}

struct WorkshopsView:View {
	var body: some View {
		VStack{
			Text("🛞🛠️ Nearby Workshops")
				.font(.largeTitle)
		}
	}
}

struct ProfileView:View {
	var body: some View {
		VStack{
			Text("👀 PROFILE")
				.font(.largeTitle)
		}
	}
}
#Preview {
    HomeView(authVM: AuthenticationViewModel(context: PersistenceController.shared.container.viewContext))
}
