// SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var settingsQuery: [AppSettings]
    @Query(sort: \OperationLog.startTime, order: .reverse) private var logs: [OperationLog]
    
    @State private var selectedTab = 0
    
    private var settings: AppSettings {
        if let existing = settingsQuery.first {
            return existing
        } else {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            return newSettings
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Content
            TabView(selection: $selectedTab) {
                generalSettingsTab
                    .tabItem {
                        Label("General", systemImage: "gearshape")
                    }
                    .tag(0)
                
                historyTab
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(1)
                
                aboutTab
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
                    .tag(2)
            }
            .frame(minWidth: 600, minHeight: 400)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - General Settings
    
    private var generalSettingsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                GlassCard(padding: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Application")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Toggle(isOn: Binding(
                            get: { settings.autoCheckUpdates },
                            set: { newValue in
                                settings.autoCheckUpdates = newValue
                                settings.updateTimestamp()
                                try? modelContext.save()
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Auto-check for updates")
                                    .font(.body)
                                Text("Check for app updates daily")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                        
                        Divider()
                        
                        Toggle(isOn: Binding(
                            get: { settings.showConsoleByDefault },
                            set: { newValue in
                                settings.showConsoleByDefault = newValue
                                settings.updateTimestamp()
                                try? modelContext.save()
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Show console by default")
                                    .font(.body)
                                Text("Automatically show console output during operations")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                        
                        Divider()
                        
                        Toggle(isOn: Binding(
                            get: { settings.enableAnimations },
                            set: { newValue in
                                settings.enableAnimations = newValue
                                settings.updateTimestamp()
                                try? modelContext.save()
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enable animations")
                                    .font(.body)
                                Text("Use smooth animations and transitions")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                    }
                }
                
                GlassCard(padding: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Information")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if let version = settings.lastSpicetifyVersion {
                            infoRow(label: "Spicetify Version", value: version)
                        }
                        
                        if let lastCheck = settings.lastUpdateCheck {
                            infoRow(label: "Last Update Check", value: lastCheck.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - History Tab
    
    private var historyTab: some View {
        ScrollView {
            VStack(spacing: 12) {
                if logs.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Operation history will appear here")
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    ForEach(logs) { log in
                        logCard(log)
                    }
                }
            }
            .padding()
        }
    }
    
    private func logCard(_ log: OperationLog) -> some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: statusIcon(for: log.status))
                        .foregroundStyle(statusColor(for: log.status))
                    
                    Text(log.operation.capitalized)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(log.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(log.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let error = log.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }
        }
    }
    
    // MARK: - About Tab
    
    private var aboutTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Icon
                Image(systemName: "music.note.list")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .glow(color: .blue, radius: 30, opacity: 0.5)
                
                VStack(spacing: 8) {
                    Text("SpicetifyGUI-MacOS")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                GlassCard(padding: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("A modern macOS GUI for Spicetify CLI")
                            .font(.body)
                            .foregroundStyle(.primary)
                        
                        Text("Easily manage your Spotify customizations with a beautiful glass-morphic interface.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://spicetify.app")!) {
                    HStack {
                        Image(systemName: "link.circle.fill")
                        Text("Visit Spicetify Website")
                    }
                    .font(.body)
                    .foregroundStyle(.blue)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Views
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.primary)
                .fontWeight(.medium)
        }
        .font(.body)
    }
    
    private func statusIcon(for status: String) -> String {
        switch status {
        case "success": return "checkmark.circle.fill"
        case "failed": return "xmark.circle.fill"
        case "inProgress": return "clock.fill"
        default: return "circle.fill"
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "success": return .green
        case "failed": return .red
        case "inProgress": return .blue
        default: return .gray
        }
    }
}

