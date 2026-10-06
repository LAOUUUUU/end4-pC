import Foundation

public enum SpotifyBridgeError: Error, Equatable {
    /// osascript failed. The message is its stderr, for example a denied automation request.
    case scriptFailed(String)
}

/// Reads what Spotify is playing by running AppleScript through `osascript`.
/// Read-only: it never sends play, pause or skip commands.
public enum SpotifyBridge {
    /// Prints one separator-delimited line, or nothing when Spotify is not running or has no track.
    /// Checks `is running` first so it never launches Spotify.
    public static let readScript = #"""
    set sep to ASCII character 31
    if application "Spotify" is not running then return ""
    tell application "Spotify"
      try
        set t to current track
        return (id of t) & sep & (name of t) & sep & (artist of t) & sep & (album of t) & sep & ((duration of t) as text) & sep & ((player position) as text) & sep & ((player state) as text) & sep & (artwork url of t) & sep & ((shuffling) as text) & sep & ((repeating) as text)
      on error
        return ""
      end try
    end tell
    """#

    /// Current playback, `nil` when nothing is playing, or an error when the script could not run.
    public static func read() async -> Result<PlaybackSnapshot?, SpotifyBridgeError> {
        let run = await run(script: readScript)
        return interpret(exitCode: run.exitCode, stdout: run.stdout, stderr: run.stderr)
    }

    /// Pure decision: a non-zero exit is an error, even when stdout is empty.
    public static func interpret(
        exitCode: Int32,
        stdout: String,
        stderr: String
    ) -> Result<PlaybackSnapshot?, SpotifyBridgeError> {
        guard exitCode == 0 else {
            return .failure(.scriptFailed(stderr.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        return .success(SpotifyPlaybackParser.parse(stdout))
    }

    /// Runs AppleScript through `osascript` and returns its exit code and output.
    public static func run(script: String) async -> (exitCode: Int32, stdout: String, stderr: String) {
        await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]

            let out = Pipe()
            let err = Pipe()
            process.standardOutput = out
            process.standardError = err

            do {
                try process.run()
            } catch {
                return (1, "", error.localizedDescription)
            }
            // Read both pipes before waiting, so a full pipe cannot block the child.
            let stdout = String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            let stderr = String(decoding: err.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            process.waitUntilExit()
            return (process.terminationStatus, stdout, stderr)
        }.value
    }
}
