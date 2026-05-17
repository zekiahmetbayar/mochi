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

# Build per-arch and ask SwiftPM exactly where it dropped each binary +
# resource bundle. Hard-coded paths bit us once (resources missing from the
# .app), so we use `--show-bin-path` instead of guessing.
swift build -c release --arch arm64
ARM_BIN_DIR="$(swift build -c release --arch arm64 --show-bin-path)"
swift build -c release --arch x86_64
X86_BIN_DIR="$(swift build -c release --arch x86_64 --show-bin-path)"

ARM_BIN="$ARM_BIN_DIR/Mochi"
X86_BIN="$X86_BIN_DIR/Mochi"
[[ -f "$ARM_BIN" ]] || { echo "missing $ARM_BIN" >&2; exit 1; }
[[ -f "$X86_BIN" ]] || { echo "missing $X86_BIN" >&2; exit 1; }

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

echo "==> Combining binaries"
lipo -create -output "$APP/Contents/MacOS/Mochi" "$ARM_BIN" "$X86_BIN"
chmod +x "$APP/Contents/MacOS/Mochi"

echo "==> Copying resource bundles from $ARM_BIN_DIR"
shopt -s nullglob
copied=0
for b in "$ARM_BIN_DIR"/*.bundle; do
    [[ -d "$b" ]] || continue
    cp -R "$b" "$APP/Contents/Resources/"
    echo "    + $(basename "$b")"
    copied=$((copied + 1))
done
shopt -u nullglob

# The app loads this bundle from Contents/Resources at runtime.
if [[ ! -d "$APP/Contents/Resources/Mochi_MochiApp.bundle" ]]; then
    echo "ERROR: Mochi_MochiApp.bundle was not copied (found $copied bundles)" >&2
    echo "Contents of $ARM_BIN_DIR:" >&2
    ls -la "$ARM_BIN_DIR" >&2
    exit 1
fi

echo "==> Generating app icon"
ICON_SRC="Mochi/Assets/logo.png"
ICONSET="$OUT_DIR/Mochi.iconset"
[[ -f "$ICON_SRC" ]] || { echo "missing $ICON_SRC" >&2; exit 1; }
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
sips -z 16 16     "$ICON_SRC" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32     "$ICON_SRC" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32     "$ICON_SRC" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64     "$ICON_SRC" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128   "$ICON_SRC" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256   "$ICON_SRC" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$ICON_SRC" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512   "$ICON_SRC" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$ICON_SRC" --out "$ICONSET/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$ICON_SRC" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/Mochi.icns"
rm -rf "$ICONSET"

echo "==> Writing Info.plist"
sed "s/__VERSION__/$VERSION/g" scripts/Info.plist > "$APP/Contents/Info.plist"

echo "==> Ad-hoc codesigning"
# Ad-hoc signing lets the app run after the user clears Gatekeeper once.
# To switch to Developer-ID signing + notarization, set the relevant env
# vars in CI and replace this block accordingly.
codesign --force --deep --sign - --options runtime --timestamp=none "$APP"
codesign --verify --verbose "$APP"

echo "==> Built $APP"
