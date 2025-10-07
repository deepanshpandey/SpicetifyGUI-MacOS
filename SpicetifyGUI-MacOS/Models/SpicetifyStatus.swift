// SpicetifyStatus.swift
import Foundation
import SwiftUI

enum SpicetifyStatus: Equatable {
    case notInstalled
    case installed(version: String)
    case applied
    case unknown
    
    var displayText: String {
        switch self {
        case .notInstalled:
            return "Not Installed"
        case .installed(let version):
            return "Installed (v\(version))"
        case .applied:
            return "Applied & Active"
        case .unknown:
            return "Unknown"
        }
    }
    
    var description: String {
        switch self {
        case .notInstalled:
            return "Spicetify is not installed on your system"
        case .installed(let version):
            return "Version \(version) is ready to be applied"
        case .applied:
            return "Spicetify is active and customizing Spotify"
        case .unknown:
            return "Unable to determine Spicetify status"
        }
    }
    
    var iconName: String {
        switch self {
        case .notInstalled:
            return "xmark.circle.fill"
        case .installed:
            return "checkmark.circle.fill"
        case .applied:
            return "checkmark.seal.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .notInstalled:
            return .red
        case .installed:
            return .orange
        case .applied:
            return .green
        case .unknown:
            return .gray
        }
    }
    
    var isInstalled: Bool {
        if case .notInstalled = self {
            return false
        }
        return true
    }
}
