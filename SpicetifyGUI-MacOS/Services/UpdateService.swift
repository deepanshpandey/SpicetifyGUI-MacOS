// UpdateService.swift
import Foundation
import SwiftData
import AppKit

class UpdateService {
    
    static let shared = UpdateService()
    
    private let githubRepo = "https://github.com/deepanshpandey/SpicetifyGUI-MacOS"
    private let currentVersion = "1.0.0" //
    
    private init() {}
    
    // Check for app updates
    func checkForUpdates() async throws -> UpdateInfo? {
        let url = URL(string: "https://api.github.com/repos/\(githubRepo)/releases/latest")!
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("SpicetifyGUI-MacOS/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.networkError("Invalid response")
            }
            
            // Handle rate limiting
            if httpResponse.statusCode == 403 {
                throw AppError.networkError("GitHub API rate limit exceeded. Please try again later.")
            }
            
            guard httpResponse.statusCode == 200 else {
                throw AppError.networkError("Failed to fetch update information (Status: \(httpResponse.statusCode))")
            }
            
            let decoder = JSONDecoder()
            let updateInfo = try decoder.decode(UpdateInfo.self, from: data)
            
            // Compare versions
            if isNewerVersion(updateInfo.version, than: currentVersion) {
                return updateInfo
            }
            
            return nil
        } catch let error as DecodingError {
            throw AppError.parseError("Failed to parse update information: \(error.localizedDescription)")
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.networkError(error.localizedDescription)
        }
    }
    
    // Download and install update
    func downloadAndInstallUpdate(
        _ updateInfo: UpdateInfo,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        
        // Find macOS asset (DMG, ZIP, or PKG)
        let macExtensions = [".dmg", ".zip", ".pkg"]
        guard let asset = updateInfo.assets.first(where: { asset in
            macExtensions.contains(where: { asset.name.lowercased().hasSuffix($0) })
        }) else {
            throw AppError.updateFailed("No macOS installer found in release assets")
        }
        
        progressHandler(0.0, "Preparing download...")
        
        guard let downloadURL = URL(string: asset.browserDownloadUrl) else {
            throw AppError.updateFailed("Invalid download URL")
        }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let destinationURL = tempDirectory.appendingPathComponent(asset.name)
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: destinationURL)
        
        progressHandler(0.1, "Downloading \(asset.name)...")
        
        // Download with progress tracking
        let downloadTask = URLSession.shared.downloadTask(with: downloadURL)
        
        let downloadedURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            var observation: NSKeyValueObservation?
            
            downloadTask.resume()
            
            observation = downloadTask.progress.observe(\.fractionCompleted) { progress, _ in
                let percentage = progress.fractionCompleted
                let downloaded = ByteCountFormatter.string(fromByteCount: progress.completedUnitCount, countStyle: .file)
                let total = ByteCountFormatter.string(fromByteCount: progress.totalUnitCount, countStyle: .file)
                
                DispatchQueue.main.async {
                    progressHandler(0.1 + (percentage * 0.8), "Downloading: \(downloaded) / \(total)")
                }
            }
            
            // Store completion handler
            let completionHandler: (URL?, URLResponse?, Error?) -> Void = { url, response, error in
                observation?.invalidate()
                
                if let error = error {
                    continuation.resume(throwing: AppError.networkError("Download failed: \(error.localizedDescription)"))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    continuation.resume(throwing: AppError.networkError("Download failed with invalid response"))
                    return
                }
                
                guard let url = url else {
                    continuation.resume(throwing: AppError.networkError("Download completed but file is missing"))
                    return
                }
                
                continuation.resume(returning: url)
            }
            
            // Use objc_setAssociatedObject to store handler (workaround for async)
            objc_setAssociatedObject(downloadTask, "handler", completionHandler as Any, .OBJC_ASSOCIATION_RETAIN)
        }
        
        progressHandler(0.9, "Finalizing download...")
        
        // Move to temp directory with proper name
        try FileManager.default.moveItem(at: downloadedURL, to: destinationURL)
        
        progressHandler(0.95, "Opening installer...")
        
        // Open the installer
        let workspace = NSWorkspace.shared
        
        if asset.name.hasSuffix(".dmg") {
            // Mount DMG and open
            try await mountAndOpenDMG(at: destinationURL)
        } else {
            // Open ZIP or PKG directly
            workspace.open(destinationURL)
        }
        
        progressHandler(1.0, "Update ready to install!")
        
        // Show alert and quit
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let alert = NSAlert()
            alert.messageText = "Update Downloaded"
            alert.informativeText = "The installer is ready. The app will now quit so you can complete the installation."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Quit & Install")
            
            alert.runModal()
            NSApplication.shared.terminate(nil)
        }
    }
    
    // Mount DMG and open
    private func mountAndOpenDMG(at url: URL) async throws {
        let shell = ShellExecutor.shared
        
        // Mount the DMG
        let mountOutput = try await shell.execute("hdiutil attach '\(url.path)' -nobrowse")
        
        // Extract mount point
        let lines = mountOutput.components(separatedBy: .newlines)
        guard let mountLine = lines.last(where: { $0.contains("/Volumes/") }),
              let mountPoint = mountLine.components(separatedBy: "\t").last?.trimmingCharacters(in: .whitespaces) else {
            throw AppError.updateFailed("Failed to mount DMG")
        }
        
        // Open the mounted volume
        NSWorkspace.shared.open(URL(fileURLWithPath: mountPoint))
    }
    
    // Compare semantic versions
    private func isNewerVersion(_ new: String, than current: String) -> Bool {
        let newComponents = new.split(separator: ".").compactMap { Int($0) }
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(newComponents.count, currentComponents.count)
        
        for i in 0..<maxLength {
            let newValue = i < newComponents.count ? newComponents[i] : 0
            let currentValue = i < currentComponents.count ? currentComponents[i] : 0
            
            if newValue > currentValue {
                return true
            } else if newValue < currentValue {
                return false
            }
        }
        
        return false
    }
    
    // Save last check time to settings
    func updateLastCheckTime(in context: ModelContext) {
        let descriptor = FetchDescriptor<AppSettings>()
        
        if let settings = try? context.fetch(descriptor).first {
            settings.lastUpdateCheck = Date()
            settings.updateTimestamp()
            try? context.save()
        }
    }
    
    // Check if should auto-check for updates
    func shouldAutoCheck(settings: AppSettings?) -> Bool {
        guard let settings = settings, settings.autoCheckUpdates else {
            return false
        }
        
        guard let lastCheck = settings.lastUpdateCheck else {
            return true
        }
        
        // Check once per day
        let dayInSeconds: TimeInterval = 24 * 60 * 60
        return Date().timeIntervalSince(lastCheck) > dayInSeconds
    }
}

