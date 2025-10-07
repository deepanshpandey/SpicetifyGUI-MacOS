
// MainView.swift
import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = MainViewModel()
    @State private var showRemoveConfirmation = false
    @State private var showRestoreConfirmation = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.25),
                    Color(red: 0.1, green: 0.15, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main Content
            VStack(spacing: 0) {
                // Custom Title Bar
                titleBar
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Status Card
                        StatusCard(status: viewModel.status)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        
                        // Config Info (if available)
                        if !viewModel.configInfo.isEmpty {
                            configInfoCard
                                .padding(.horizontal, 24)
                        }
                        
                        // Action Buttons
                        actionButtons
                            .padding(.horizontal, 24)
                        
                        // Console Output
                        if viewModel.showConsole {
                            ConsoleView(
                                output: $viewModel.consoleOutput,
                                isVisible: $viewModel.showConsole,
                                onClear: { viewModel.clearConsole() }
                            )
                            .padding(.horizontal, 24)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        Spacer(minLength: 24)
                    }
                }
                
                Divider()
                    .background(.ultraThinMaterial)
                
                // Footer
                footer
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
                if let suggestion = viewModel.errorRecoverySuggestion {
                    Text("\n\(suggestion)")
                        .font(.caption)
                }
            }
        }
        .alert("Update Available", isPresented: $viewModel.showUpdateAlert) {
            Button("Later", role: .cancel) {}
            Button("Download Update") {
                Task {
                    await viewModel.installAppUpdate()
                }
            }
        } message: {
            if let update = viewModel.updateAvailable {
                Text("Version \(update.version) is available.\n\n\(update.releaseNotes.prefix(150))...")
            }
        }
        .confirmationDialog("Remove Spicetify", isPresented: $showRemoveConfirmation) {
            Button("Remove", role: .destructive) {
                Task {
                    await viewModel.remove()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove Spicetify and restore Spotify to its original state. Continue?")
        }
        .confirmationDialog("Restore Spotify", isPresented: $showRestoreConfirmation) {
            Button("Restore", role: .destructive) {
                Task {
                    await viewModel.restore()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will restore Spotify to its original state without removing Spicetify. Continue?")
        }
        .onAppear {
            viewModel.onAppear(context: modelContext)
        }
    }
    
    // MARK: - Title Bar
    
    private var titleBar: some View {
        HStack(spacing: 16) {
            // App Icon
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .blur(radius: 8)
                
                Image(systemName: "music.note")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .glow(color: .blue, radius: 15, opacity: 0.5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("SpicetifyGUI-MacOS")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let operation = viewModel.currentOperation {
                    Text(operation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await viewModel.refreshStatus()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
                .help("Refresh status")
                
                Button(action: {
                    viewModel.showSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Config Info Card
    
    private var configInfoCard: some View {
        GlassCard(padding: 16, cornerRadius: 16) {
            HStack(spacing: 16) {
                Image(systemName: "paintbrush.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let theme = viewModel.configInfo["theme"] {
                        HStack {
                            Text("Theme:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(theme)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if let colorScheme = viewModel.configInfo["colorScheme"] {
                        HStack {
                            Text("Color Scheme:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(colorScheme)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if case .notInstalled = viewModel.status {
                ActionButton(
                    title: "Install Spicetify",
                    icon: "arrow.down.circle.fill",
                    color: .green,
                    isLoading: viewModel.isLoading
                ) {
                    Task {
                        await viewModel.install()
                    }
                }
            } else {
                // Row 1: Update & Apply
                HStack(spacing: 12) {
                    ActionButton(
                        title: "Update",
                        icon: "arrow.clockwise.circle.fill",
                        color: .blue,
                        isLoading: viewModel.isLoading
                    ) {
                        Task {
                            await viewModel.update()
                        }
                    }
                    
                    ActionButton(
                        title: "Apply",
                        icon: "checkmark.circle.fill",
                        color: .green,
                        isLoading: viewModel.isLoading
                    ) {
                        Task {
                            await viewModel.apply()
                        }
                    }
                }
                
                // Row 2: Restore & Remove
                HStack(spacing: 12) {
                    ActionButton(
                        title: "Restore",
                        icon: "arrow.uturn.backward.circle.fill",
                        color: .orange,
                        isLoading: viewModel.isLoading
                    ) {
                        showRestoreConfirmation = true
                    }
                    
                    ActionButton(
                        title: "Remove",
                        icon: "trash.circle.fill",
                        color: .red,
                        isLoading: viewModel.isLoading
                    ) {
                        showRemoveConfirmation = true
                    }
                }
            }
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack(spacing: 12) {
            if viewModel.isLoading {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.7)
                    
                    if viewModel.downloadProgress > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.downloadStatus)
                                .font(.caption)
                                .foregroundStyle(.primary)
                            
                            ProgressView(value: viewModel.downloadProgress)
                                .frame(width: 200)
                        }
                    } else if let operation = viewModel.currentOperation {
                        Text(operation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Processing...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Version info
            Text("v1.0.0")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            Button(action: {
                Task {
                    await viewModel.checkForAppUpdates()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle")
                    Text("Check for Updates")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    MainView()
        .modelContainer(for: [AppSettings.self, OperationLog.self])
}
