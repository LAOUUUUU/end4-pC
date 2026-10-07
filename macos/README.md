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
3. **Scrolling lyrics.** Each line is one line of text; long lines shrink to fit the width.  The lines slide up or down on a spring as the song moves on. Each line keeps its place in the song, so the column scrolls instead of swapping text. Click any visible line to jump there. **Display.** Between polls, a local clock estimates the position so the active line advances smoothly. The window shows seven lines: the active line in the middle, three before it, and three after it. Sizes and opacities match the shell's lyrics widget.
4. **Karaoke highlight.** The active line is highlighted word by word. LRCLIB gives timestamps only per line, so each line's time is shared across its words by length. This is an estimate, not measured word timing.
5. **Visualizer.** A Core Audio process tap captures only Spotify's audio (the tap is unmuted, so playback is not affected). It is active only while Spotify is playing. The audio is split into 24 log-spaced bands with an FFT.
6. **Playback buttons.** Shuffle, previous, play/pause, next, and repeat. Each sends one AppleScript command and checks that Spotify is running first, so a click never launches it. Shuffle and repeat show their current state from Spotify, in the accent colour. A thin bar under the title shows how far through the track playback is.
7. **Album colours.** The track's cover URL comes from Spotify's AppleScript. The app downloads the cover, shrinks it to 48×48, and picks its four most prominent colours. Vivid colours count for more than large grey areas. The first vivid colour is the accent, which tints the bars and the sung words. All four form the window's background gradient. If the cover has no vivid colour (for example, black and white), the default cyan is used.
9. **Volume.** A slider sets Spotify's volume (0–100) when you let go of it. It follows Spotify's current volume and does not fight the drag.
10. **Now Playing view.** The ⤢ button in the header switches to a larger layout with the cover, the visualizer, large lyrics, and the controls. The cover is shown with the text "Cover art from Spotify" and an "Open in Spotify" link, which Spotify's developer policy asks for. The window animates between the two sizes.
11. **Animation.** Lyric lines spring into place and fade as the song moves on. The play/pause icon morphs between its two states. The window keeps a fixed size, so content changes do not make it jump while you drag it.
8. **Click a line to jump.** Clicking a lyric line moves Spotify to that line's start time. This changes the playback position, so it only happens on a click.
12. **Seek bar.** Click or drag the progress bar to move to that point in the track. This is ported from the shell's media controls.
13. **Blurred cover background.** The Now Playing view puts the cover behind its gradient, blurred and faded, as the shell's media widget does.

### Buttons

Buttons are Material-style, ported from the shell's ripple button: a flash from the press, a tint on hover, corners that tighten while pressed, and an accent fill when toggled on. The active lyric line is bold; the rest are regular weight, crossfading as the active line changes.

### Main menu

The lyric panel is editable:

- **Resize** it by dragging its edges (300 × 260 pt at least). It remembers its size and place between launches.
- **Move** it by dragging any empty part.
- A small grip in the bottom-right corner is a visible handle for resizing, since the panel's borderless edges give no hint that they are draggable too.
- **Choose what it shows** under Settings → Lyric panel: the visualizer, and the progress bar, volume and controls.

The full-screen main menu opens when EndLyrics starts. While the menu is the focused window, the lyric panel steps aside. It returns as soon as you switch to another app or Space, and steps aside again when you come back to the menu. Turn this off under Settings → "Open the main menu when EndLyrics starts". The lyric window is still shown alongside it.

Lyrics → **Copy All Lyrics** (⌥⌘⇧C) copies the whole song's lyrics to the clipboard, as plain text.

The **♪** item in the menu bar opens a **full-screen main menu**: a real macOS full-screen page with the blurred cover as its background, large lyrics and cover art on the left, and a grid of tiles on the right. It has the playback controls, the timing and save actions, the Now Playing and compact toggles, Settings, and Quit. Press Esc or the ✕ to leave. You can also open it with ⇧⌘M from the View menu. Right-click ♪ for the plain menu.

The system menu bar at the top of the screen cannot be drawn in custom colours by any app, so it keeps macOS's style.

The lyric window's corners are rounded, and its shadow follows the rounded shape.

The full-screen menu has a widget column, ported from the shell's widgets:

- **Clock and world clocks.** Local time with Tokyo, London, and New York underneath.
- **CPU and memory.** Sampled every two seconds from Mach host statistics, like the shell's resources widget.
- **Timer.** A 5, 15, 30, or 60 minute countdown. With "Pause music when it ends" on, it pauses playback when it reaches zero.
- **Notes.** A free-text pad, saved between launches.
- **To-do.** Add, tick off, and remove tasks, saved between launches.
- **Device.** macOS version, uptime, and battery charge (from `IOPSCopyPowerSourcesInfo`, the same API System Settings uses).
- **Clipboard history.** The last 30 things you copied (text only), polled from the pasteboard once a second. Click an entry to copy it back. Ported from the shell's Cliphist.

### AI chat

The **Ai** page in the full-screen menu is a chat with Claude, using your own Anthropic API key. It is the macOS equivalent of the shell's generic LLM chat (`Ai.qml`), narrowed to Claude.

- Add your key under Settings → AI chat. It is stored in your login keychain (`io.github.endlyrics.anthropic-api-key`), never in UserDefaults or a settings file.
- Nothing is sent until a key is set; the Ai page shows a prompt to add one instead.
- Pick the model (Sonnet, Opus, or Haiku) under the same settings.
- Requests go straight from your Mac to `api.anthropic.com/v1/messages`. The app has no server of its own.

### Lyrics translation

On macOS 15 and later, Settings → Lyrics translation shows a translation of the active line underneath it, using Apple's on-device Translation framework (`TranslationSession`). This is the macOS equivalent of the shell's `GoogleCloud.qml` plus `Translation.qml`, done without a Google Cloud project, a service-account key, or sending lyrics to a server: translation runs on the device. Apple's own note is that it may log the app and the language pair, never the text.

The columns size to the window, so the menu fits any screen size. Now Playing has its own button to return to the standard size.

Not ported yet: the weather and calendar widgets, which need an outside weather service or calendar permission; and song recognition (SongRec), which would need ShazamKit.

Deliberately not ported: the shell's anime image-board browser (Booru) mixes in adult content even on tagged-safe boards, so it is not in this app. Its AI chat widget and its Google Cloud integration would need your own API key (and, for Google, a sign-in), so they wait for you to say which provider and supply the key yourself. The equalizer depends on EasyEffects, which is Linux-only.

### Saving lyrics

**Lyrics → Save as .lrc…** writes the lyrics currently loaded, with `[ti:]` and `[ar:]` headers and `[mm:ss.cc]` timestamps. Turn on **Millisecond Timestamps** for `[mm:ss.mmm]`. **Save as .txt…** writes the lines without timestamps. The suggested file name is `Artist - Title.lrc`.

### What is not included, and why

The Manzana project (MIT) fetches lyrics from Apple Music with your logged-in `media-user-token` cookie, and makes lyric videos in its paid tiers. Its Apple Music fetch is not in this app: it relies on a private web API that needs your browser session token, and Apple's official lyrics endpoint needs a privileged developer token that cannot be shipped in an app. Lyric videos and word-level sync are sold products.

### Players

The window follows **Spotify**, **Apple Music**, or **whichever is playing** (Settings → Player). Apple Music is read and controlled through its AppleScript dictionary, which has the same playback properties as Spotify's. Automatic mode checks Spotify first, then Apple Music, and runs both reads each second while nothing is playing. Apple Music does not expose a cover URL, so its track has no album-colour palette and falls back to the default cyan.

**Apple Music support is not yet checked against a running Music app.** The parser and scripts are unit tested. Verify with Music open and a song playing.

### Keeping permissions across builds

macOS keys its permissions (Automation for Spotify and Music, System Audio Recording, notifications) to the app's code signature. `scripts/build-app.sh` signs with a local certificate named **EndLyrics Local**, so the signature stays the same from one build to the next and macOS keeps your grants.

The certificate is self-signed and lives in your login keychain, not in an Apple developer account. Create it once with `openssl` and import it with `security import` (the private key is only in the keychain). If it is missing, the script falls back to ad-hoc signing, and macOS asks for the permissions again after each build. Override the name with `ENDLYRICS_SIGN_IDENTITY`.

The first build after switching asks for the permissions once more.

### Settings

Settings is a page inside the full-screen main menu. Open it from ♪ or ⌘, and switch between **Home** and **Settings** at the top. There are no separate windows.

The lyric size and the cover blur are settings too.

- **Colour presets.** Six one-tap accents: Cyan, Rose, Amber, Mint, Violet, and Mono. Picking one switches the accent to a solid colour.
- **Background image.** Choose your own picture for the background, or go back to the cover.
- **Track notifications.** A notification when the track changes. Off by default. macOS asks for permission the first time.
- **Open at login.** Starts EndLyrics when you log in. macOS may only allow this once the app is in `/Applications`.
 **Copy Current Lyric** (⌥⌘C) copies the line being sung.

| Setting | What it does |
|---|---|
| Style | **Bars**, **Mirror** (reflected around the centre), **Dots** (columns of dots), **Wave** (a smooth line), **Radial** (bars around a circle), or **LED blocks**. |
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
| `Sources/LyricsCore` (`LyricsExport`) | LRC and TXT writers, safe file names |
| `Sources/AppleMusicKit` | Apple Music AppleScript reads, controls and parser |
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
