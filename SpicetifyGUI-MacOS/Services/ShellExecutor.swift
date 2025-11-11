import Foundation

// MARK: - Thread-safe accumulator to collect concurrent output
private final class OutputAccumulator: @unchecked Sendable {
    private let storage = NSMutableString()
    private let lock = NSLock()
    
    func append(_ string: String) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(string)
    }
    
    func value() -> String {
        lock.lock()
        defer { lock.unlock() }
        return String(storage)
    }
}

// MARK: - ShellExecutor
final class ShellExecutor {
    static let shared = ShellExecutor()
    private init() {}

    // MARK: - Public Methods
    
    /// Executes a shell command and returns the full output once complete.
    @discardableResult
    func execute(_ command: String, environment: [String: String]? = nil) async throws -> String {
        try await runProcess(command, environment: environment, streamOutput: nil)
    }

    /// Executes a command and streams output live via a callback.
    @discardableResult
    func executeWithRealTimeOutput(
        _ command: String,
        environment: [String: String]? = nil,
        outputHandler: @escaping (String) -> Void
    ) async throws -> String {
        try await runProcess(command, environment: environment, streamOutput: outputHandler)
    }

    /// Check if a command exists in the user’s environment.
    func checkCommandExists(_ command: String) async -> Bool {
        do {
            let output = try await execute("command -v \(command)")
            return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            return false
        }
    }

    /// Get the version string for a given CLI tool.
    func getCommandVersion(_ command: String, versionFlag: String = "-v") async -> String? {
        do {
            let output = try await execute("\(command) \(versionFlag)")
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    /// Check whether Spotify is installed in the usual locations.
    func checkSpotifyInstalled() async -> Bool {
        let fm = FileManager.default
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let spotifyPaths = [
            "/Applications/Spotify.app",
            "\(home)/Applications/Spotify.app"
        ]
        return spotifyPaths.contains { fm.fileExists(atPath: $0) }
    }

    // MARK: - Private Core Execution
    
    private func runProcess(
        _ command: String,
        environment: [String: String]?,
        streamOutput: ((String) -> Void)?
    ) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let task = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            let accumulator = OutputAccumulator()
            
            // Use user’s login shell (zsh -l -c)
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
            task.arguments = ["-l", "-c", command]
            task.standardOutput = outputPipe
            task.standardError = errorPipe
            
            // Merge environment with PATH fixes
            var env = ProcessInfo.processInfo.environment
            if let extra = environment {
                for (key, value) in extra {
                    env[key] = value
                }
            } else {
                let home = FileManager.default.homeDirectoryForCurrentUser.path
                let additionalPaths = [
                    "\(home)/.spicetify",
                    "\(home)/.local/bin",
                    "/usr/local/bin",
                    "/opt/homebrew/bin"
                ]
                if let existingPath = env["PATH"] {
                    env["PATH"] = additionalPaths.joined(separator: ":") + ":" + existingPath
                }
            }
            task.environment = env
            
            // Stream stdout
            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                    Task{ @MainActor in
                        accumulator.append(output)
                    }
                    if let stream = streamOutput {
                        Task { @MainActor in stream(output) }
                    }
                }
            }
            
            // Stream stderr
            errorPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                    Task{ @MainActor in
                        accumulator.append(output)
                    }
                    if let stream = streamOutput {
                        Task { @MainActor in stream(output) }
                    }
                }
            }
            
            // Handle termination
            task.terminationHandler = { process in
                outputPipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil
                
                // Read any remaining output
                let remainingOut = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let remainingErr = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                if let out = String(data: remainingOut, encoding: .utf8), !out.isEmpty {
                    Task{ @MainActor in
                        accumulator.append(out)
                    }
                }
                if let err = String(data: remainingErr, encoding: .utf8), !err.isEmpty {
                    Task{ @MainActor in
                        accumulator.append(err)
                    }
                }
                Task{ @MainActor in
                    let result = accumulator.value()
                    if process.terminationStatus == 0 {
                        continuation.resume(returning: result)
                    } else {
                        continuation.resume(throwing: AppError.commandFailed(result))
                    }
                }
            }
            
            do {
                try task.run()
            } catch {
                continuation.resume(throwing: AppError.commandFailed(error.localizedDescription))
            }
        }
    }
}
