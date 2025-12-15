// NotificationSettingsView.swift
// DriveBuddy
// Improved with better status messages and calendar sync

import SwiftUI
import UserNotifications
import CoreData
import EventKit

struct NotificationSettingsView: View {
    @ObservedObject var profileVM: ProfileViewModel
    @State private var isAnimating = false
    @State private var showStatusMessage = false
    @State private var statusMessage = ""
    @State private var statusMessageType: MessageType = .success
    
    enum MessageType {
        case success, error, warning
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Dark Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 8) {
                    Text("Notification Settings")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .blue, radius: 10)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)

                VStack(spacing: 24) {
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
                    
                    // ✅ Status Message Toast
                    if showStatusMessage {
                        HStack(spacing: 12) {
                            Image(systemName: statusMessageType.icon)
                                .foregroundColor(statusMessageType.color)
                                .font(.title3)
                            
                            Text(statusMessage)
                                .foregroundColor(.white)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(statusMessageType.color.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(statusMessageType.color.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.3), value: showStatusMessage)
                    }
                    
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
                                    await handleTaxReminderToggle(newValue)
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
                                    await handleServiceReminderToggle(newValue)
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
                                handleAddToCalendarToggle(newValue)
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
                    
                    // Test Notification Button
                    Button(action: {
                        Task {
                            await sendTestNotification()
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
                    .disabled(profileVM.notificationStatus != .authorized)
                    .opacity(profileVM.notificationStatus == .authorized ? 1.0 : 0.5)
                    .padding(.horizontal, 16)
                    
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
    
    // MARK: - Toggle Handlers
    private func handleTaxReminderToggle(_ newValue: Bool) async {
        await profileVM.toggleTaxReminder(newValue)
        
        if newValue {
            if profileVM.notificationStatus == .authorized {
                showMessage("Tax reminders enabled", type: .success)
            } else {
                showMessage("Please enable notifications in settings", type: .warning)
            }
        } else {
            showMessage("Tax reminders disabled", type: .success)
        }
    }
    
    private func handleServiceReminderToggle(_ newValue: Bool) async {
        await profileVM.toggleServiceReminder(newValue)
        
        if newValue {
            if profileVM.notificationStatus == .authorized {
                showMessage("Service reminders enabled", type: .success)
            } else {
                showMessage("Please enable notifications in settings", type: .warning)
            }
        } else {
            showMessage("Service reminders disabled", type: .success)
        }
    }
    
    private func handleAddToCalendarToggle(_ newValue: Bool) {
        Task {
            if newValue {
                // Check current permission status
                if profileVM.calendarStatus == .authorized || profileVM.calendarStatus == .fullAccess {
                    // ✅ Update the toggle state first
                    await MainActor.run {
                        profileVM.toggleAddToCalendar(newValue)
                    }
                    
                    await profileVM.syncAllVehiclesToCalendar()
                    showMessage("Calendar sync enabled. Events added to calendar", type: .success)
                    
                } else if profileVM.calendarStatus == .notDetermined {
                    // Request permission if not determined
                    await profileVM.requestCalendarPermission()
                    await profileVM.checkPermissionStatuses()
                    
                    if profileVM.calendarStatus == .authorized || profileVM.calendarStatus == .fullAccess {
                        await MainActor.run {
                            profileVM.toggleAddToCalendar(true)
                        }
                        await profileVM.syncAllVehiclesToCalendar()
                        showMessage("Calendar sync enabled. Events added to calendar", type: .success)
                    } else {
                        // Force UI update
                        await MainActor.run {
                            profileVM.addToCalendar = false
                        }
                        showMessage("Calendar permission denied", type: .error)
                    }
                } else {
                    // Permission denied - force toggle back to off
                    await MainActor.run {
                        profileVM.addToCalendar = false
                    }
                    showMessage("Please enable calendar access in settings", type: .warning)
                }
            } else {
                // ✅ Turning OFF - remove events
                await MainActor.run {
                    profileVM.toggleAddToCalendar(newValue)
                }
                // Events will be removed automatically in toggleAddToCalendar
                showMessage("Calendar sync disabled. Events removed from calendar", type: .success)
            }
        }
    }
    
    private func sendTestNotification() async {
        await profileVM.sendTestNotification()
        
        if profileVM.notificationStatus == .authorized {
            showMessage("Test notification sent!", type: .success)
        } else {
            showMessage("Notification permission required", type: .error)
        }
    }
    
    // MARK: - Status Message Helper
    private func showMessage(_ message: String, type: MessageType) {
        statusMessage = message
        statusMessageType = type
        withAnimation {
            showStatusMessage = true
        }
        
        // Auto-hide after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation {
                showStatusMessage = false
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
            
            // ✅ FIXED: Use custom binding instead of onChange
            Toggle("", isOn: Binding(
                get: { isOn.wrappedValue },
                set: { newValue in
                    action(newValue)
                }
            ))
            .labelsHidden()
            .tint(.cyan)
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
