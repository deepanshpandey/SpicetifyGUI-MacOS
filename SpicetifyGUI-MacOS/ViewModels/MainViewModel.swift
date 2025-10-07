//
//  MainViewModel.swift
//  SpicetifyGUI-MacOS
//
//  Created by Deepansh Pandey on 06/10/25.
//

// MainViewModel.swift
import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class MainViewModel: ObservableObject {
    
    @Published var status: SpicetifyStatus = .unknown
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var errorRecoverySuggestion: String?
    @Published var errorIcon: String = "exclamationmark.triangle.fill"
    @Published var showError = false
    @Published var consoleOutput = ""
    @Published var showConsole = false
    @Published var updateAvailable: UpdateInfo?
    @Published var showUpdateAlert = false
    @Published var downloadProgress: Double = 0.0
    @Published var downloadStatus: String = ""
    @Published var currentOperation: String?
    @Published var configInfo: [String: String] = [:]
    @Published var showSettings = false
    
    private let spicetifyService = SpicetifyService.shared
    private let updateService = UpdateService.shared
    private var currentLog: OperationLog?
    
    var modelContext: ModelContext?
    
    init() {
        Task {
            await refreshStatus()
        }
    }
    
    // MARK: - Lifecycle
    
    func onAppear(context: ModelContext) {
        self.modelContext = context
        
        Task {
            await checkForAppUpdatesIfNeeded()
            await loadConfigInfo()
        }
    }
    
    // MARK: - Spicetify Operations
    
    func refreshStatus() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            status = try await spicetifyService.checkStatus()
            await loadConfigInfo()
        } catch {
            handleError(error)
        }
    }
    
    func install() async {
        guard let context = modelContext else { return }
        
        currentOperation = "Installing Spicetify"
        isLoading = true
        consoleOutput = ""
        showConsole = true
        
        // Create log entry
        let log = OperationLog(operation: "install")
        context.insert(log)
        currentLog = log
        
        do {
            try await spicetifyService.install { [weak self] output in
                self?.consoleOutput += output
            }
            
            // Update log
            log.complete(success: true, output: consoleOutput)
            try? context.save()
            
            await refreshStatus()
            
            // Update settings with version
            if case .installed(let version) = status {
                updateSettings { settings in
                    settings.lastSpicetifyVersion = version
                }
            }
            
        } catch {
            log.complete(success: false, output: consoleOutput, error: error.localizedDescription)
            try? context.save()
            handleError(error)
        }
        
        isLoading = false
        currentOperation = nil
        currentLog = nil
    }
    
    func update() async {
        guard let context = modelContext else { return }
        
        currentOperation = "Updating Spicetify"
        isLoading = true
        consoleOutput = ""
        showConsole = true
        
        let log = OperationLog(operation: "update")
        context.insert(log)
        currentLog = log
        
        do {
            try await spicetifyService.update { [weak self] output in
                self?.consoleOutput += output
            }
            
            log.complete(success: true, output: consoleOutput)
            try? context.save()
            
            await refreshStatus()
            
            if case .installed(let version) = status {
                updateSettings { settings in
                    settings.lastSpicetifyVersion = version
                }
            }
            
        } catch {
            log.complete(success: false, output: consoleOutput, error: error.localizedDescription)
            try? context.save()
            handleError(error)
        }
        
        isLoading = false
        currentOperation = nil
        currentLog = nil
    }
    
    func remove() async {
        guard let context = modelContext else { return }
        
        currentOperation = "Removing Spicetify"
        isLoading = true
        consoleOutput = ""
        showConsole = true
        
        let log = OperationLog(operation: "remove")
        context.insert(log)
        currentLog = log
        
        do {
            try await spicetifyService.remove { [weak self] output in
                self?.consoleOutput += output
            }
            
            log.complete(success: true, output: consoleOutput)
            try? context.save()
            
            await refreshStatus()
            
            updateSettings { settings in
                settings.lastSpicetifyVersion = nil
                settings.installationPath = nil
            }
            
        } catch {
            log.complete(success: false, output: consoleOutput, error: error.localizedDescription)
            try? context.save()
            handleError(error)
        }
        
        isLoading = false
        currentOperation = nil
        currentLog = nil
    }
    
    func apply() async {
        guard let context = modelContext else { return }
        
        currentOperation = "Applying Spicetify"
        isLoading = true
        consoleOutput = ""
        showConsole = true
        
        let log = OperationLog(operation: "apply")
        context.insert(log)
        currentLog = log
        
        do {
            try await spicetifyService.apply { [weak self] output in
                self?.consoleOutput += output
            }
            
            log.complete(success: true, output: consoleOutput)
            try? context.save()
            
            await refreshStatus()
            
        } catch {
            log.complete(success: false, output: consoleOutput, error: error.localizedDescription)
            try? context.save()
            handleError(error)
        }
        
        isLoading = false
        currentOperation = nil
        currentLog = nil
    }
    
    func restore() async {
        guard let context = modelContext else { return }
        
        currentOperation = "Restoring Spotify"
        isLoading = true
        consoleOutput = ""
        showConsole = true
        
        let log = OperationLog(operation: "restore")
        context.insert(log)
        currentLog = log
        
        do {
            try await spicetifyService.restore { [weak self] output in
                self?.consoleOutput += output
            }
            
            log.complete(success: true, output: consoleOutput)
            try? context.save()
            
            await refreshStatus()
            
        } catch {
            log.complete(success: false, output: consoleOutput, error: error.localizedDescription)
            try? context.save()
            handleError(error)
        }
        
        isLoading = false
        currentOperation = nil
        currentLog = nil
    }
    
    // MARK: - App Update Operations
    
    func checkForAppUpdatesIfNeeded() async {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<AppSettings>()
        guard let settings = try? context.fetch(descriptor).first else { return }
        
        if updateService.shouldAutoCheck(settings: settings) {
            await checkForAppUpdates()
            updateService.updateLastCheckTime(in: context)
        }
    }
    
    func checkForAppUpdates() async {
        do {
            if let update = try await updateService.checkForUpdates() {
                updateAvailable = update
                showUpdateAlert = true
            }
        } catch {
            // Silently fail for update checks
            print("Update check failed: \(error.localizedDescription)")
        }
    }
    
    func installAppUpdate() async {
        guard let update = updateAvailable else { return }
        
        isLoading = true
        downloadProgress = 0.0
        
        do {
            try await updateService.downloadAndInstallUpdate(update) { [weak self] progress, status in
                self?.downloadProgress = progress
                self?.downloadStatus = status
            }
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func handleError(_ error: Error) {
        if let appError = error as? AppError {
            errorMessage = appError.errorDescription
            errorRecoverySuggestion = appError.recoverySuggestion
            errorIcon = appError.iconName
        } else {
            errorMessage = error.localizedDescription
            errorRecoverySuggestion = nil
            errorIcon = "exclamationmark.triangle.fill"
        }
        showError = true
    }
    
    func clearConsole() {
        consoleOutput = ""
    }
    
    private func loadConfigInfo() async {
        configInfo = await spicetifyService.getConfigInfo()
    }
    
    private func updateSettings(update: (AppSettings) -> Void) {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<AppSettings>()
        if let settings = try? context.fetch(descriptor).first {
            update(settings)
            settings.updateTimestamp()
            try? context.save()
        } else {
            let newSettings = AppSettings()
            update(newSettings)
            context.insert(newSettings)
            try? context.save()
        }
    }
    
    func getRecentLogs() -> [OperationLog] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<OperationLog>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        return (try? context.fetch(descriptor).prefix(10).map { $0 }) ?? []
    }
}

