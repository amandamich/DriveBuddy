// NotificationSettingsView.swift
// DriveBuddy
//Created by Student on 26/11/25.

import SwiftUI
import UserNotifications
import CoreData
import EventKit

struct NotificationSettingsView: View {
    @ObservedObject var profileVM: ProfileViewModel
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Dark Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    Text("Notification Settings")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .cyan.opacity(0.5), radius: 5)
                        .padding(.top, 40)
                    
                    // Permission Status Card
                    VStack(spacing: 16) {
                        permissionStatusRow(
                            icon: "bell.fill",
                            title: "Notifications",
                            status: profileVM.notificationStatus
                        )
                        
                        permissionStatusRow(
                            icon: "calendar",
                            title: "Calendar",
                            status: profileVM.calendarStatus
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 10)
                    )
                    .padding(.horizontal, 16)
                    
                    // Reminder Settings
                    VStack(spacing: 0) {
                        // Tax Reminder Toggle
                        reminderToggleRow(
                            icon: "dollarsign.circle.fill",
                            title: "Tax Reminder",
                            subtitle: "Yearly reminder for vehicle tax renewal",
                            isOn: $profileVM.taxReminderEnabled,
                            action: { newValue in
                                Task {
                                    await profileVM.toggleTaxReminder(newValue)
                                }
                            }
                        )
                        
                        Divider()
                            .background(Color.cyan.opacity(0.3))
                            .padding(.leading, 56)
                        
                        // Service Reminder Toggle
                        reminderToggleRow(
                            icon: "wrench.fill",
                            title: "Service Reminder",
                            subtitle: "Reminders for upcoming vehicle services",
                            isOn: $profileVM.serviceReminderEnabled,
                            action: { newValue in
                                Task {
                                    await profileVM.toggleServiceReminder(newValue)
                                }
                            }
                        )
                        
                        Divider()
                            .background(Color.cyan.opacity(0.3))
                            .padding(.leading, 56)
                        
                        // Add to Calendar Toggle
                        reminderToggleRow(
                            icon: "calendar.badge.plus",
                            title: "Add to Calendar",
                            subtitle: "Automatically add events to calendar",
                            isOn: $profileVM.addToCalendar,
                            action: { newValue in
                                profileVM.toggleAddToCalendar(newValue)
                            }
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 10)
                    )
                    .padding(.horizontal, 16)
                    
                    // ✅ SYNC ALL TO CALENDAR BUTTON
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Calendar Sync")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Add all existing vehicles and their tax due dates to your calendar")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            Task {
                                await profileVM.syncAllVehiclesToCalendar()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundColor(.cyan)
                                Text("Sync All to Calendar")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
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
                        .disabled(profileVM.calendarStatus != .authorized ||
                                  profileVM.addToCalendar != true)
                        .opacity((profileVM.calendarStatus == .authorized &&
                                  profileVM.addToCalendar == true) ? 1.0 : 0.5)
                        
                        if profileVM.calendarStatus != .authorized ||
                           profileVM.addToCalendar != true {
                            Text("Enable calendar permission and 'Add to Calendar' first")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 10)
                    )
                    .padding(.horizontal, 16)
                    
                    // Test Notification Button
                    Button(action: {
                        Task {
                            await profileVM.sendTestNotification()
                        }
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.cyan)
                            Text("Send Test Notification")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
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
                    .padding(.horizontal, 16)
                    
                    // Success/Error Messages
                    if let success = profileVM.successMessage {
                        Text(success)
                            .foregroundColor(.green)
                            .font(.caption)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    if let error = profileVM.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    // Info Text
                    Text("Enable reminders to never miss important vehicle maintenance dates")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 16)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await profileVM.checkPermissionStatuses()
            }
        }
    }
    
    // MARK: - Permission Status Row
    @ViewBuilder
    private func permissionStatusRow(
        icon: String,
        title: String,
        status: UNAuthorizationStatus
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 16))
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor(for: status))
                    .frame(width: 8, height: 8)
                
                Text(statusText(for: status))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if status == .denied {
                Button(action: {
                    profileVM.openAppSettings()
                }) {
                    Text("Settings")
                        .font(.caption)
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.cyan.opacity(0.2))
                        )
                }
            }
        }
    }
    
    @ViewBuilder
    private func permissionStatusRow(
        icon: String,
        title: String,
        status: EKAuthorizationStatus
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 16))
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(calendarStatusColor(for: status))
                    .frame(width: 8, height: 8)
                
                Text(calendarStatusText(for: status))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if status == .denied {
                Button(action: {
                    profileVM.openAppSettings()
                }) {
                    Text("Settings")
                        .font(.caption)
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.cyan.opacity(0.2))
                        )
                }
            }
        }
    }
    
    // MARK: - Reminder Toggle Row
    @ViewBuilder
    private func reminderToggleRow(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        action: @escaping (Bool) -> Void
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                
                Text(subtitle)
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.cyan)
                .onChange(of: isOn.wrappedValue) { oldValue, newValue in
                    action(newValue)
                }
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    private func statusColor(for status: UNAuthorizationStatus) -> Color {
        switch status {
        case .authorized: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        case .provisional: return .yellow
        case .ephemeral: return .yellow
        @unknown default: return .gray
        }
    }
    
    private func statusText(for status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Enabled"
        case .denied: return "Disabled"
        case .notDetermined: return "Not Set"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
    
    private func calendarStatusColor(for status: EKAuthorizationStatus) -> Color {
        switch status {
        case .authorized: return .green
        case .denied, .restricted: return .red
        case .notDetermined: return .orange
        case .fullAccess: return .green
        case .writeOnly: return .yellow
        @unknown default: return .gray
        }
    }
    
    private func calendarStatusText(for status: EKAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Enabled"
        case .denied: return "Disabled"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Set"
        case .fullAccess: return "Full Access"
        case .writeOnly: return "Write Only"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Preview
#Preview {
    let context = PersistenceController.shared.container.viewContext
    let mockUser = User(context: context)
    mockUser.email = "preview@drivebuddy.com"
    
    let profileVM = ProfileViewModel(context: context, user: mockUser)
    
    return NavigationStack {
        NotificationSettingsView(profileVM: profileVM)
    }
}
