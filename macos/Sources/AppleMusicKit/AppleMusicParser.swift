import Foundation
import SpotifyKit

/// Parses the line printed by `AppleMusicScript.readScript`. Fields are separated by 0x1F.
public enum AppleMusicParser {
    public static func parse(_ output: String) -> PlaybackSnapshot? {
        let line = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return nil }

        let fields = line.components(separatedBy: "\u{1F}")
        guard fields.count == 9 else { return nil }

        let name = fields[1]
        guard !name.isEmpty else { return nil }
        guard
            let duration = Double(fields[4]),
            let position = Double(fields[5]),
            let state = SpotifyPlayerState(rawValue: fields[6])
        else { return nil }

        return PlaybackSnapshot(
            trackID: "music:\(fields[0])",
            title: name,
            artist: fields[2],
            album: fields[3],
            duration: duration,
            position: position,
            state: state,
            artworkURL: nil,
            shuffling: fields[7] == "true",
            // Apple Music repeats "one" or "all"; "off" is no repeat.
            repeating: fields[8] != "off",
            volume: 0
        )
    }
}
