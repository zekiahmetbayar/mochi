#!/usr/bin/env bash
# Assembles Mochi.app from a SwiftPM release build.
# Produces a universal (arm64 + x86_64) binary so the same DMG runs on both
# Apple Silicon and Intel Macs.
#
# Usage: scripts/build-app.sh <version>
set -euo pipefail

VERSION="${1:-0.0.0}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

OUT_DIR="build"
APP="$OUT_DIR/Mochi.app"

echo "==> Building Mochi $VERSION (universal)"
mkdir -p "$OUT_DIR"

# Build per-arch so we can lipo into a universal binary. SwiftPM doesn't
# always produce a usable universal output via `--arch a --arch b` for app
# bundling, so we do two passes and combine.
swift build -c release --arch arm64
swift build -c release --arch x86_64

ARM_BIN=".build/arm64-apple-macosx/release/Mochi"
X86_BIN=".build/x86_64-apple-macosx/release/Mochi"
[[ -f "$ARM_BIN" ]] || { echo "missing $ARM_BIN" >&2; exit 1; }
[[ -f "$X86_BIN" ]] || { echo "missing $X86_BIN" >&2; exit 1; }

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

echo "==> Combining binaries"
lipo -create -output "$APP/Contents/MacOS/Mochi" "$ARM_BIN" "$X86_BIN"
chmod +x "$APP/Contents/MacOS/Mochi"

echo "==> Copying resource bundles"
shopt -s nullglob
for b in .build/arm64-apple-macosx/release/*.bundle; do
    cp -R "$b" "$APP/Contents/Resources/"
done
shopt -u nullglob

echo "==> Writing Info.plist"
sed "s/__VERSION__/$VERSION/g" scripts/Info.plist > "$APP/Contents/Info.plist"

echo "==> Ad-hoc codesigning"
# Ad-hoc signing lets the app run after the user clears Gatekeeper once.
# To switch to Developer-ID signing + notarization, set the relevant env
# vars in CI and replace this block accordingly.
codesign --force --deep --sign - --options runtime --timestamp=none "$APP"
codesign --verify --verbose "$APP"

echo "==> Built $APP"
