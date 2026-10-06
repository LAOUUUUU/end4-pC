#!/bin/bash
# Builds a release binary and wraps it in EndLyrics.app, signed with the local identity (see README).
set -euo pipefail

cd "$(dirname "$0")/.."

swift build -c release

APP="build/EndLyrics.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp ".build/release/EndLyrics" "$APP/Contents/MacOS/EndLyrics"
cp "Resources/Info.plist" "$APP/Contents/Info.plist"
# A stable identity keeps macOS permissions (Automation, audio capture, notifications) across rebuilds.
# Falls back to ad-hoc signing, which makes macOS ask for those permissions again after every build.
IDENTITY="${ENDLYRICS_SIGN_IDENTITY:-EndLyrics Local}"
if security find-identity -p codesigning | grep -q "\"$IDENTITY\""; then
    codesign --force --sign "$IDENTITY" "$APP"
else
    echo "warning: signing identity '$IDENTITY' not found; using ad-hoc signing (permissions reset on each build)" >&2
    codesign --force --sign - "$APP"
fi

echo "Built $APP"
