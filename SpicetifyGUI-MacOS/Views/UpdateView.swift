// UpdateView.swift
import SwiftUI

struct UpdateView: View {
    let updateInfo: UpdateInfo
    let onDownload: () -> Void
    let onDismiss: () -> Void
    
    @State private var isHovering = false
    @State private var showFullNotes = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Update Card
            VStack(spacing: 0) {
                // Header
                header
                
                Divider()
                    .background(.white.opacity(0.1))
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Version Info
                        versionInfo
                        
                        // Release Notes
                        releaseNotes
                        
                        // Download Info
                        if let asset = updateInfo.assets.first {
                            downloadInfo(asset: asset)
                        }
                    }
                    .padding(24)
                }
                .frame(maxHeight: 400)
                
                Divider()
                    .background(.white.opacity(0.1))
                
                // Actions
                actions
            }
            .frame(width: 500)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.15),
                                        .white.opacity(0.05),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .white.opacity(0.1),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isHovering)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .blur(radius: 10)
                
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .glow(color: .blue, radius: 20, opacity: 0.6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Update Available")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("A new version is ready to download")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Version Info
    
    private var versionInfo: some View {
        GlassCard(padding: 20, cornerRadius: 16) {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Version")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    Text(updateInfo.version)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                Spacer()
                
                if let date = updateInfo.formattedPublishedDate {
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        Text(date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Release Notes
    
    private var releaseNotes: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("What's New")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if updateInfo.releaseNotes.count > 300 {
                    Button(action: {
                        showFullNotes.toggle()
                    }) {
                        Text(showFullNotes ? "Show Less" : "Show More")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            GlassCard(padding: 16, cornerRadius: 12) {
                Text(showFullNotes ? updateInfo.releaseNotes : String(updateInfo.releaseNotes.prefix(300)) + (updateInfo.releaseNotes.count > 300 ? "..." : ""))
                    .font(.body)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(.easeInOut, value: showFullNotes)
            }
        }
    }
    
    // MARK: - Download Info
    
    private func downloadInfo(asset: UpdateInfo.Asset) -> some View {
        GlassCard(padding: 16, cornerRadius: 12) {
            HStack(spacing: 12) {
                Image(systemName: "doc.zipper.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.name)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(asset.formattedSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
        }
    }
    
    // MARK: - Actions
    
    private var actions: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Text("Later")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            
            Button(action: onDownload) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title3)
                    
                    Text("Download & Install")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }
}

// MARK: - Preview

#Preview {
    UpdateView(
        updateInfo: UpdateInfo(
            tagName: "v2.0.0",
            name: "SpicetifyGUI-MacOS v2.0.0",
            htmlUrl: "https://github.com/user/repo",
            body: """
            ## What's New
            
            - Beautiful new liquid glass UI design
            - Improved performance and stability
            - Enhanced error handling
            - New settings panel with operation history
            - Auto-update functionality
            - Support for macOS Sequoia
            
            ## Bug Fixes
            
            - Fixed installation issues on Apple Silicon
            - Resolved console output display problems
            - Improved Spotify detection
            """,
            assets: [
                UpdateInfo.Asset(
                    name: "SpicetifyGUI-MacOS-v2.0.0.dmg",
                    browserDownloadUrl: "https://github.com/user/repo/releases/download/v2.0.0/app.dmg",
                    size: 15_000_000
                )
            ],
            publishedAt: "2025-10-06T12:00:00Z"
        ),
        onDownload: {},
        onDismiss: {}
    )
}
