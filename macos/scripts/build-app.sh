#!/bin/bash
# Builds a release binary and wraps it in EndLyrics.app (ad-hoc signed, for personal use).
set -euo pipefail

cd "$(dirname "$0")/.."

swift build -c release

APP="build/EndLyrics.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp ".build/release/EndLyrics" "$APP/Contents/MacOS/EndLyrics"
cp "Resources/Info.plist" "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"

echo "Built $APP"
