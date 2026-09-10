import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var unitsSettings: UnitsSettings
    @AppStorage("showPopularResorts") private var showPopularResorts = true

    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var testResult: TestResult?

    private enum TestResult { case sent, notAuthorized }

    var body: some View {
        List {
            Section("Notifications") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(statusLabel).foregroundStyle(.secondary)
                }

                if authStatus == .denied {
                    Button("Enable in iOS Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                } else if authStatus == .notDetermined {
                    Button("Request Permission") {
                        Task {
                            await NotificationManager.shared.requestAuthorizationIfNeeded()
                            authStatus = await NotificationManager.shared.authorizationStatus()
                        }
                    }
                }

                Button {
                    Task {
                        let sent = await NotificationManager.shared.sendTestNotification()
                        testResult = sent ? .sent : .notAuthorized
                        Haptics.tap()
                    }
                } label: {
                    Label("Send Test Notification", systemImage: "bell.badge")
                }

                if let testResult {
                    switch testResult {
                    case .sent:
                        Text("Sent — it should appear in a second.")
                            .font(.caption)
                            .foregroundStyle(.green)
                    case .notAuthorized:
                        Text("Not authorized yet — request permission above first.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Text("Favorited resorts are checked for ≥2cm of snow in the next 2 days whenever you open the app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)

            Section("Preferences") {
                Picker("Units", selection: $unitsSettings.preference) {
                    Text("Metric").tag(UnitsPreference.metric)
                    Text("Imperial").tag(UnitsPreference.imperial)
                }
                Toggle("Show Popular Resorts", isOn: $showPopularResorts)
            }
            .listRowBackground(Color.clear)

            Section("Camera Sources") {
                statusRow(title: "Windy Webcams", configured: WebcamAPIConfig.isConfigured)
                statusRow(title: "YouTube Live", configured: YouTubeAPIConfig.isConfigured)
            }
            .listRowBackground(Color.clear)

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion).foregroundStyle(.secondary)
                }
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            authStatus = await NotificationManager.shared.authorizationStatus()
        }
    }

    private var statusLabel: String {
        switch authStatus {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Requested"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }

    private func statusRow(title: String, configured: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(configured ? "Configured" : "Not Set")
                .foregroundStyle(configured ? .green : .secondary)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
