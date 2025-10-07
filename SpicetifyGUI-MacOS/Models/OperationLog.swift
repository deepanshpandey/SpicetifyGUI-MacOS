// OperationLog.swift
import Foundation
import SwiftData

@Model
final class OperationLog {
    var id: UUID
    var operation: String // "install", "update", "remove", "apply", "restore"
    var status: String // "success", "failed", "inProgress"
    var output: String
    var errorMessage: String?
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval?
    
    init(
        id: UUID = UUID(),
        operation: String,
        status: String = "inProgress",
        output: String = "",
        errorMessage: String? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.operation = operation
        self.status = status
        self.output = output
        self.errorMessage = errorMessage
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
    }
    
    func complete(success: Bool, output: String, error: String? = nil) {
        self.status = success ? "success" : "failed"
        self.output = output
        self.errorMessage = error
        self.endTime = Date()
        if let end = endTime {
            self.duration = end.timeIntervalSince(startTime)
        }
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "N/A" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
    
    var statusColor: String {
        switch status {
        case "success": return "green"
        case "failed": return "red"
        case "inProgress": return "blue"
        default: return "gray"
        }
    }
}
