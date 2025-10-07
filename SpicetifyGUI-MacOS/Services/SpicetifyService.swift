// SpicetifyService.swift
import Foundation
import SwiftData

class SpicetifyService {
    
    static let shared = SpicetifyService()
    private let shell = ShellExecutor.shared
    
    private init() {}
    
    // Check Spicetify installation status
    func checkStatus() async throws -> SpicetifyStatus {
        let exists = await shell.checkCommandExists("spicetify")
        
        if !exists {
            return .notInstalled
        }
        
        // Get version
        guard let version = await shell.getCommandVersion("spicetify", versionFlag: "-v") else {
            return .unknown
        }
        
        // Check if applied by looking at config-xpui.ini
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let configPath = "\(homeDir)/.config/spicetify/config-xpui.ini"
        
        if FileManager.default.fileExists(atPath: configPath),
           let _ = try? String(contentsOfFile: configPath, encoding: .utf8) {
            // Check if backup exists (means spicetify has been applied)
            let backupPath = "\(homeDir)/.config/spicetify/Backup"
            if FileManager.default.fileExists(atPath: backupPath) {
                return .applied
            }
        }
        
        return .installed(version: version)
    }
    
    // Install Spicetify
    func install(outputHandler: @escaping (String) -> Void) async throws {
        // Check if Spotify is installed first
        let spotifyInstalled = await shell.checkSpotifyInstalled()
        if !spotifyInstalled {
            throw AppError.spotifyNotFound
        }
        
        outputHandler("🔍 Checking prerequisites...\n")
        outputHandler("✅ Spotify found\n\n")
        outputHandler("📥 Starting Spicetify installation...\n")
        outputHandler("This may take a few minutes...\n\n")
        
        do {
            let installScript = """
            curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh
            """
            
            _ = try await shell.executeWithRealTimeOutput(installScript, outputHandler: outputHandler)
            
            outputHandler("\n✅ Installation completed successfully!\n")
            outputHandler("💡 Tip: Click 'Apply' to activate Spicetify on Spotify\n")
        } catch {
            throw AppError.installationFailed(error.localizedDescription)
        }
    }
    
    // Update Spicetify
    func update(outputHandler: @escaping (String) -> Void) async throws {
        outputHandler("🔄 Checking for Spicetify updates...\n\n")
        
        do {
            // Get current version
            let currentVersion = await shell.getCommandVersion("spicetify", versionFlag: "-v") ?? "unknown"
            outputHandler("Current version: \(currentVersion)\n\n")
            
            outputHandler("📥 Downloading latest version...\n")
            
            let updateScript = """
            curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh
            """
            
            _ = try await shell.executeWithRealTimeOutput(updateScript, outputHandler: outputHandler)
            
            // Get new version
            let newVersion = await shell.getCommandVersion("spicetify", versionFlag: "-v") ?? "unknown"
            
            outputHandler("\n✅ Update completed!\n")
            outputHandler("New version: \(newVersion)\n")
            
            if currentVersion != newVersion {
                outputHandler("\n💡 Version changed! You may need to re-apply Spicetify.\n")
            }
        } catch {
            throw AppError.updateFailed(error.localizedDescription)
        }
    }
    
    // Remove Spicetify
    func remove(outputHandler: @escaping (String) -> Void) async throws {
        outputHandler("🗑️  Starting Spicetify removal...\n\n")
        
        // Restore Spotify first
        outputHandler("⏪ Restoring Spotify to original state...\n")
        do {
            _ = try await shell.execute("spicetify restore")
            outputHandler("✅ Spotify restored\n\n")
        } catch {
            outputHandler("⚠️  Could not restore (may not be applied)\n\n")
        }
        
        // Remove spicetify directories
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let pathsToRemove = [
            "\(homeDir)/.spicetify",
            "\(homeDir)/.config/spicetify",
            "\(homeDir)/.local/bin/spicetify"
        ]
        
        outputHandler("🧹 Removing Spicetify files...\n")
        for path in pathsToRemove {
            if FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.removeItem(atPath: path)
                outputHandler("  ✓ Removed: \(path)\n")
            }
        }
        
        outputHandler("\n✅ Spicetify removed successfully!\n")
        outputHandler("ℹ️  Spotify has been restored to its original state.\n")
    }
    
    // Apply Spicetify
    func apply(outputHandler: @escaping (String) -> Void) async throws {
        outputHandler("🎨 Applying Spicetify to Spotify...\n\n")
        
        do {
            // Check if Spotify is running
            outputHandler("🔍 Checking if Spotify is running...\n")
            let spotifyRunning = try await shell.execute("pgrep -x Spotify")
            if !spotifyRunning.isEmpty {
                outputHandler("⚠️  Spotify is running. It will be closed automatically.\n\n")
            }
            
            // Backup first
            outputHandler("💾 Creating backup...\n")
            do {
                _ = try await shell.executeWithRealTimeOutput("spicetify backup", outputHandler: outputHandler)
                outputHandler("✅ Backup created\n\n")
            } catch {
                outputHandler("ℹ️  Backup already exists or not needed\n\n")
            }
            
            // Apply
            outputHandler("✨ Applying Spicetify...\n")
            _ = try await shell.executeWithRealTimeOutput("spicetify apply", outputHandler: outputHandler)
            
            outputHandler("\n🎉 Spicetify applied successfully!\n")
            outputHandler("🚀 Spotify will launch with your customizations.\n")
            outputHandler("\n💡 Tips:\n")
            outputHandler("  • Use 'spicetify config' to customize themes\n")
            outputHandler("  • Visit spicetify.app for themes and extensions\n")
        } catch {
            throw AppError.applyFailed(error.localizedDescription)
        }
    }
    
    // Restore Spotify to original state
    func restore(outputHandler: @escaping (String) -> Void) async throws {
        outputHandler("⏪ Restoring Spotify to original state...\n\n")
        
        do {
            // Check if Spotify is running
            let spotifyRunning = try? await shell.execute("pgrep -x Spotify")
            if let running = spotifyRunning, !running.isEmpty {
                outputHandler("⚠️  Closing Spotify...\n")
                _ = try? await shell.execute("killall Spotify")
                try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second
            }
            
            outputHandler("🔄 Running restore command...\n")
            _ = try await shell.executeWithRealTimeOutput("spicetify restore", outputHandler: outputHandler)
            
            outputHandler("\n✅ Spotify restored successfully!\n")
            outputHandler("ℹ️  All customizations have been removed.\n")
            outputHandler("💡 You can re-apply Spicetify anytime by clicking 'Apply'.\n")
        } catch {
            throw AppError.applyFailed(error.localizedDescription)
        }
    }
    
    // Get Spicetify config info
    func getConfigInfo() async -> [String: String] {
        var info: [String: String] = [:]
        
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let configPath = "\(homeDir)/.config/spicetify/config-xpui.ini"
        
        if let config = try? String(contentsOfFile: configPath, encoding: .utf8) {
            // Parse basic info from config
            let lines = config.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("current_theme") {
                    let parts = line.split(separator: "=")
                    if parts.count == 2 {
                        info["theme"] = parts[1].trimmingCharacters(in: .whitespaces)
                    }
                }
                if line.contains("color_scheme") {
                    let parts = line.split(separator: "=")
                    if parts.count == 2 {
                        info["colorScheme"] = parts[1].trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }
        
        return info
    }
}
