# EndLyrics for macOS

A small floating window that shows synced lyrics for whatever is playing in the Spotify desktop app. It is a macOS companion to the lyrics widget in end4-pC. It reads playback from Spotify and never modifies the Spotify app.

## Requirements

- macOS 14 or later
- Spotify desktop app
- Xcode command-line tools (Swift 6)

## Build and run

```bash
cd macos
./scripts/build-app.sh
open build/EndLyrics.app
```

The first time it reads Spotify, macOS asks whether EndLyrics may control Spotify. Click **Allow**. If you clicked Don't Allow, turn it on under **System Settings > Privacy & Security > Automation**.

The app runs from the menu bar (♪). Use it to show or hide the lyrics window, or quit.

## How it works

1. **Playback.** Every second, EndLyrics runs a read-only AppleScript through `osascript` that asks Spotify for the current track and playback position. It never sends play, pause, or skip commands.
2. **Lyrics.** For each new track it looks up synced lyrics on [LRCLIB](https://lrclib.net), a free public API. It tries three lookups in order and accepts the first result whose title and artist match. Results are cached under `~/Library/Caches/EndLyrics/lyrics`, so a replayed track does not hit the network again.
3. **Display.** Between polls, a local clock estimates the position so the active line advances smoothly. The window shows seven lines: the active line in the middle, three before it, and three after it. Sizes and opacities match the shell's lyrics widget.

## Tests

```bash
cd macos
swift test
```

The unit tests run offline. To also run the live tests against LRCLIB:

```bash
ENDLYRICS_LIVE_TESTS=1 swift test --filter LRCLibLiveTests
```

## Layout

| Path | Contents |
|---|---|
| `Sources/LyricsCore` | LRC parsing, matching, active-line logic, LRCLIB client, cache, position clock |
| `Sources/SpotifyKit` | AppleScript bridge and playback parser |
| `Sources/EndLyrics` | SwiftUI lyrics view, model, and the AppKit panel and menu bar item |
| `Tests/` | Unit tests for each core piece, plus opt-in live tests |
| `Resources/Info.plist` | Bundle metadata, including the Automation usage string |
| `scripts/build-app.sh` | Release build, app bundle, and ad-hoc signing |

## Differences from the shell widget

- **Colors.** The shell derives its colors from the wallpaper. This app uses a fixed dark style.
- **Backdrop and position.** The shell widget sits directly on the wallpaper. This app puts the lyrics on a dark rounded backdrop so they stay readable, and opens the panel at the top-left of the main screen, below the menu bar.
- **Cover art and track info.** Not shown. Spotify's developer policy has rules about showing its content next to other content, and the policy's application to this kind of app is unresolved.
- **Empty track name.** The Python lookup treated an empty name as matching every title. This version rejects it.
- **Before the first line.** Every slot is blank. The shell's version shows the first lines in the bottom slots.
- **Duration.** Spotify reports track length in milliseconds, even though its AppleScript dictionary says seconds. This version converts it.

## Limitations and open questions

- **Spotify's developer policy.** The [Developer Policy](https://developer.spotify.com/policy) covers apps that use the Spotify Platform. It is not clear whether an app that only reads the desktop client through AppleScript falls under it. Ask Spotify before any public release.
- **Lyrics licensing.** LRCLIB states no terms, and its lyrics are user-contributed. Treat this as personal use until that is clarified.
- **Ads.** During an ad, Spotify may report no current track. The app then shows "Nothing playing in Spotify". This has not been checked during a real ad.
- **Spotify updates.** Spotify can change its AppleScript dictionary in any update. If a read fails, the window shows the error message from `osascript`. This failure path is covered by a unit test, not tested against a real broken Spotify.
- **Platform.** Built and tested on macOS 26 only.
