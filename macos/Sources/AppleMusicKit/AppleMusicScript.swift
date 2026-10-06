import Foundation
import SpotifyKit

/// AppleScript for the Music app, using the same playback properties as Spotify's.
/// Every command checks `is running` first, so it never launches Music.
public enum AppleMusicScript {
    /// One line of fields: persistent id, name, artist, album, duration, position, state, shuffle, repeat.
    public static let readScript = #"""
    set sep to ASCII character 31
    if application "Music" is not running then return ""
    tell application "Music"
      try
        set t to current track
        return (persistent ID of t) & sep & (name of t) & sep & (artist of t) & sep & (album of t) & sep & ((duration of t) as text) & sep & ((player position) as text) & sep & ((player state) as text) & sep & ((shuffle enabled) as text) & sep & ((song repeat) as text)
      on error
        return ""
      end try
    end tell
    """#

    public static func command(_ verb: String) -> String {
        guardedScript("\(verb)")
    }

    public static func seek(to seconds: Double) -> String {
        guardedScript("set player position to \(max(0, seconds))")
    }

    public static func volume(_ level: Int) -> String {
        guardedScript("set sound volume to \(min(100, max(0, level)))")
    }

    public static func shuffle(on: Bool) -> String {
        guardedScript("set shuffle enabled to \(on)")
    }

    public static func repeating(on: Bool) -> String {
        guardedScript("set song repeat to \(on ? "all" : "off")")
    }

    private static func guardedScript(_ statement: String) -> String {
        """
        if application "Music" is running then tell application "Music" to \(statement)
        """
    }
}
