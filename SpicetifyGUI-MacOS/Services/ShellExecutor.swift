// ShellExecutor.swift
import Foundation

// Thread-safe accumulator to collect output across concurrently executing closures
private final class OutputAccumulator: @unchecked Sendable {
    nonisolated(unsafe) private let storage: NSMutableString = NSMutableString()
    private let lock = NSLock()

    nonisolated func append(_ string: String) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(string)
    }

    nonisolated func value() -> String {
        lock.lock()
        defer { lock.unlock() }
        return String(storage)
    }
}

class ShellExecutor {
    
    static let shared = ShellExecutor()
    
    private init() {}
    
    @discardableResult
    func execute(_ command: String, environment: [String: String]? = nil) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let task = Process()
            let pipe = Pipe()
            let errorPipe = Pipe()
            
            task.standardOutput = pipe
            task.standardError = errorPipe
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = ["-c", command]
            
            // Set environment variables
            if let env = environment {
                var processEnv = ProcessInfo.processInfo.environment
                for (key, value) in env {
                    processEnv[key] = value
                }
                task.environment = processEnv
            } else {
                // Ensure PATH includes common locations
                var processEnv = ProcessInfo.processInfo.environment
                let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
                let additionalPaths = [
                    "\(homeDir)/.spicetify",
                    "\(homeDir)/.local/bin",
                    "/usr/local/bin",
                    "/opt/homebrew/bin"
                ]
                if let existingPath = processEnv["PATH"] {
                    processEnv["PATH"] = additionalPaths.joined(separator: ":") + ":" + existingPath
                }
                task.environment = processEnv
            }
            
            task.terminationHandler = { process in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                
                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    let error = errorOutput.isEmpty ? output : errorOutput
                    continuation.resume(throwing: AppError.commandFailed(error))
                }
            }
            
            do {
                try task.run()
            } catch {
                continuation.resume(throwing: AppError.commandFailed(error.localizedDescription))
            }
        }
    }
    
    func executeWithRealTimeOutput(
        _ command: String,
        environment: [String: String]? = nil,
        outputHandler: @escaping (String) -> Void
    ) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let task = Process()
            let pipe = Pipe()
            let errorPipe = Pipe()
            
            task.standardOutput = pipe
            task.standardError = errorPipe
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = ["-c", command]
            
            // Set environment variables
            if let env = environment {
                var processEnv = ProcessInfo.processInfo.environment
                for (key, value) in env {
                    processEnv[key] = value
                }
                task.environment = processEnv
            } else {
                var processEnv = ProcessInfo.processInfo.environment
                let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
                let additionalPaths = [
                    "\(homeDir)/.spicetify",
                    "\(homeDir)/.local/bin",
                    "/usr/local/bin",
                    "/opt/homebrew/bin"
                ]
                if let existingPath = processEnv["PATH"] {
                    processEnv["PATH"] = additionalPaths.joined(separator: ":") + ":" + existingPath
                }
                task.environment = processEnv
            }
            
            let accumulator = OutputAccumulator()
            // Handle standard output
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                    accumulator.append(output)
                    Task { @MainActor in
                        outputHandler(output)
                    }
                }
            }
            // Handle error output
            errorPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                    accumulator.append(output)
                    Task { @MainActor in
                        outputHandler(output)
                    }
                }
            }
            task.terminationHandler = { process in
                pipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil
                // Read any remaining data
                let remainingData = pipe.fileHandleForReading.readDataToEndOfFile()
                let remainingErrorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                if let remaining = String(data: remainingData, encoding: .utf8), !remaining.isEmpty {
                    accumulator.append(remaining)
                }
                if let remainingError = String(data: remainingErrorData, encoding: .utf8), !remainingError.isEmpty {
                    accumulator.append(remainingError)
                }
                let result = accumulator.value()
                if process.terminationStatus == 0 {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: AppError.commandFailed(result))
                }
            }
            
            do {
                try task.run()
            } catch {
                continuation.resume(throwing: AppError.commandFailed(error.localizedDescription))
            }
        }
    }
    
    func checkCommandExists(_ command: String) async -> Bool {
        do {
            let output = try await execute("which \(command)")
            return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            return false
        }
    }
    
    func getCommandVersion(_ command: String, versionFlag: String = "-v") async -> String? {
        do {
            let output = try await execute("\(command) \(versionFlag)")
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
    
    func checkSpotifyInstalled() async -> Bool {
        let spotifyPaths = [
            "/Applications/Spotify.app",
            await MainActor.run { () -> String in
                return "\(FileManager.default.homeDirectoryForCurrentUser.path)/Applications/Spotify.app"
            }
        ]
        return await MainActor.run {
            spotifyPaths.contains { FileManager.default.fileExists(atPath: $0) }
        }
    }
}
