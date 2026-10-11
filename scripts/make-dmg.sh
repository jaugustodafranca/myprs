#!/usr/bin/env bash
# Builds the styled installer DMG: scripts/make-dmg.sh <path/to/MyPRs.app> <output.dmg>
set -euo pipefail

app="${1:?usage: make-dmg.sh <app> <dmg>}"
dmg="${2:?usage: make-dmg.sh <app> <dmg>}"
assets="$(cd "$(dirname "$0")" && pwd)/dmg"

rm -f "$dmg"

# create-dmg positions the icons with Finder via AppleScript, so it needs a GUI session.
create-dmg \
  --volname "MyPRs" \
  --volicon "$app/Contents/Resources/AppIcon.icns" \
  --background "$assets/background.tiff" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 128 \
  --text-size 13 \
  --icon "$(basename "$app")" 165 190 \
  --app-drop-link 495 190 \
  --hide-extension "$(basename "$app")" \
  --no-internet-enable \
  "$dmg" "$app"
