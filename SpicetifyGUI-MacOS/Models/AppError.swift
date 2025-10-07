// AppError.swift
import Foundation

enum AppError: LocalizedError {
    case commandFailed(String)
    case installationFailed(String)
    case updateFailed(String)
    case removalFailed(String)
    case applyFailed(String)
    case checkFailed(String)
    case networkError(String)
    case parseError(String)
    case permissionDenied
    case spotifyNotFound
    case dataAccessError(String)
    
    var errorDescription: String? {
        switch self {
        case .commandFailed(let msg):
            return "Command execution failed: \(msg)"
        case .installationFailed(let msg):
            return "Installation failed: \(msg)"
        case .updateFailed(let msg):
            return "Update failed: \(msg)"
        case .removalFailed(let msg):
            return "Removal failed: \(msg)"
        case .applyFailed(let msg):
            return "Apply operation failed: \(msg)"
        case .checkFailed(let msg):
            return "Status check failed: \(msg)"
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .parseError(let msg):
            return "Data parsing error: \(msg)"
        case .permissionDenied:
            return "Permission denied. Please check your system permissions."
        case .spotifyNotFound:
            return "Spotify application not found. Please install Spotify first."
        case .dataAccessError(let msg):
            return "Data access error: \(msg)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Try running the operation again and grant the necessary permissions."
        case .spotifyNotFound:
            return "Install Spotify from spotify.com before using Spicetify."
        case .networkError:
            return "Check your internet connection and try again."
        case .installationFailed, .updateFailed:
            return "Check the console output for more details."
        default:
            return nil
        }
    }
    
    var iconName: String {
        switch self {
        case .permissionDenied:
            return "lock.fill"
        case .spotifyNotFound:
            return "app.fill"
        case .networkError:
            return "wifi.exclamationmark"
        default:
            return "exclamationmark.triangle.fill"
        }
    }
}

