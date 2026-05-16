#!/usr/bin/env bash
# Packages build/Mochi.app into a distributable DMG with a drag-to-Applications
# layout.
#
# Usage: scripts/make-dmg.sh <version>
set -euo pipefail

VERSION="${1:-0.0.0}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP="build/Mochi.app"
[[ -d "$APP" ]] || { echo "missing $APP — run scripts/build-app.sh first" >&2; exit 1; }

DMG="build/Mochi-$VERSION.dmg"
STAGING="build/dmg-staging"

rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"

cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "==> Creating $DMG"
hdiutil create \
    -volname "Mochi" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    "$DMG" >/dev/null

# Make the DMG itself ad-hoc signed too (some Gatekeeper checks look at it).
codesign --force --sign - "$DMG"

echo "==> Built $DMG ($(du -h "$DMG" | cut -f1))"
