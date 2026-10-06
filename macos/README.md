# EndLyrics for macOS

A small floating window that shows synced lyrics for whatever is playing in the Spotify desktop app. It is a macOS companion to the lyrics widget in end4-pC. It reads playback from Spotify and never modifies the Spotify app.

## Requirements

- macOS 14.2 or later (the audio tap needs 14.2)
- Spotify desktop app
- Xcode command-line tools (Swift 6)

## Build and run

```bash
cd macos
./scripts/build-app.sh
open build/EndLyrics.app
```

The first time it reads Spotify, macOS asks whether EndLyrics may control Spotify. Click **Allow**. If you clicked Don't Allow, turn it on under **System Settings > Privacy & Security > Automation**.

The visualizer needs **System Audio Recording** permission, which macOS asks for the first time Spotify plays. It is not Screen Recording. If the bars stay flat, check **System Settings > Privacy & Security > Screen & System Audio Recording** for EndLyrics.

The app runs from the menu bar (♪). Use it to show or hide the lyrics window, or quit.

## How it works

1. **Playback.** Every second, EndLyrics runs a read-only AppleScript through `osascript` that asks Spotify for the current track and playback position. It never sends play, pause, or skip commands.
2. **Lyrics.** For each new track it looks up synced lyrics on [LRCLIB](https://lrclib.net), a free public API. It tries three lookups in order and accepts the first result whose title and artist match. Results are cached under `~/Library/Caches/EndLyrics/lyrics`, so a replayed track does not hit the network again.
3. **Display.** Between polls, a local clock estimates the position so the active line advances smoothly. The window shows seven lines: the active line in the middle, three before it, and three after it. Sizes and opacities match the shell's lyrics widget.
4. **Karaoke highlight.** The active line is highlighted word by word. LRCLIB gives timestamps only per line, so each line's time is shared across its words by length. This is an estimate, not measured word timing.
5. **Visualizer.** A Core Audio process tap captures only Spotify's audio (the tap is unmuted, so playback is not affected). It is active only while Spotify is playing. The audio is split into 24 log-spaced bands with an FFT.
6. **Playback buttons.** Previous, play/pause, and next send one AppleScript command each. Each one checks that Spotify is running first, so a click never launches it.
7. **Album colours.** The track's cover URL comes from Spotify's AppleScript. The app downloads the cover, shrinks it to 32×32, and picks its most vivid colours. The cover is never shown. The colours tint the bars, the sung words, and the window background. If the cover has no vivid colour (for example, black and white), the default cyan is used.
8. **Click a line to jump.** Clicking a lyric line moves Spotify to that line's start time. This changes the playback position, so it only happens on a click.

### Settings

Open the menu-bar ♪ item and choose **Settings…** (⌘,).

| Setting | What it does |
|---|---|
| Bars | 12, 16, 24, or 32 bars. The analyser always works in 32 bands and averages them down. |
| Show peak caps | Shows or hides the falling caps above the bars. |
| Take colours from | **Album cover** (default) or **A solid colour**, which you pick. |
| Timing offset | Shifts the lyrics by up to ±3 s, for a source that is early or late. |
| Click a line to jump there | Turns click-to-seek on or off. |
| Compact | Shows only the current line, with the header and the window background. |

Settings are saved in UserDefaults for this Mac user.

### Lyric providers

`LyricsChain` asks providers in order and uses the first answer with lines. The order is:

1. **LRCLIB** (`api/get`, `api/search`). Free, public, documented. Checked first.
2. **NetEase Cloud Music** (`music.163.com/api/search/get`, `api/song/lyric`). Used only when LRCLIB has nothing. This API is **undocumented and unofficial**. It can change or stop working without notice, and its terms are unclear. The app makes one search and one lyric request per track, sends the Referer header NetEase requires, and removes credit lines such as "作词 :" from the lyrics. Lyrics are cached after the first fetch.

The window shows which source supplied the current lyrics. Adding another source means writing one type that conforms to `LyricsProvider`.

### Checking the audio tap

```bash
open -n build/EndLyrics.app --args --audio-check
```

### Checking the album colours

```bash
open -n build/EndLyrics.app --args --palette-check
```

This reads the playing track's cover URL, downloads the cover, and writes the colours it picks to `~/Library/Caches/EndLyrics/palette-check.txt`.

This taps Spotify for three seconds as the app itself and writes the result to `~/Library/Caches/EndLyrics/audio-check.txt`. An RMS above zero means the tap is getting Spotify's audio.

## Tests

```bash
cd macos
swift test
```

The unit tests run offline. To also run the live tests, which call LRCLIB and read whatever your Spotify is playing (read-only):

```bash
ENDLYRICS_LIVE_TESTS=1 swift test --filter 'LRCLibLiveTests|SpotifyBridgeLiveTests'
```

## Layout

| Path | Contents |
|---|---|
| `Sources/LyricsCore` | LRC parsing, matching, active-line logic, LRCLIB client, cache, position clock |
| `Sources/SpotifyKit` | AppleScript bridge, playback parser and controls, Core Audio process tap |
| `Sources/AudioVisualizer` | FFT spectrum analyzer, mono mixdown, band smoothing, peak caps, resampling |
| `Sources/Appearance` | Settings model, RGB colours, dominant-colour extraction |
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
- **Cover art.** Colours are taken from the cover, which is downloaded from Spotify's image CDN. Spotify's Developer Policy has rules about its content, and the policy's application to this kind of app is unresolved. The image itself is not shown.
- **Lyrics licensing.** LRCLIB states no terms, and its lyrics are user-contributed. NetEase lyrics come from an unofficial API. Treat both as personal use only.
- **NetEase stability.** The NetEase endpoints are not documented, so they may break. If NetEase stops answering, the chain falls back to nothing and the window shows "No synced lyrics for this track."
- **Ads.** During an ad, Spotify may report no current track. The app then shows "Nothing playing in Spotify". This has not been checked during a real ad.
- **Spotify updates.** Spotify can change its AppleScript dictionary in any update. If a read fails, the window shows the error message from `osascript`. This failure path is covered by a unit test, not tested against a real broken Spotify.
- **Platform.** Built and tested on macOS 26 only.
- **Word timing.** The karaoke highlight is estimated from line timestamps. Exact word timing needs a source that publishes it.
