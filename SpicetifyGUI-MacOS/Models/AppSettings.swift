// AppSettings.swift
import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID
    var autoCheckUpdates: Bool
    var showConsoleByDefault: Bool
    var lastUpdateCheck: Date?
    var theme: String // "auto", "light", "dark"
    var enableAnimations: Bool
    var lastSpicetifyVersion: String?
    var installationPath: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        autoCheckUpdates: Bool = true,
        showConsoleByDefault: Bool = false,
        lastUpdateCheck: Date? = nil,
        theme: String = "auto",
        enableAnimations: Bool = true,
        lastSpicetifyVersion: String? = nil,
        installationPath: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.autoCheckUpdates = autoCheckUpdates
        self.showConsoleByDefault = showConsoleByDefault
        self.lastUpdateCheck = lastUpdateCheck
        self.theme = theme
        self.enableAnimations = enableAnimations
        self.lastSpicetifyVersion = lastSpicetifyVersion
        self.installationPath = installationPath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func updateTimestamp() {
        self.updatedAt = Date()
    }
}

