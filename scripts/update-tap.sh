#!/usr/bin/env bash
# Pushes a fresh cask formula to the homebrew-mochi tap repo after a release.
#
# Required env (set in the workflow):
#   GH_TOKEN          PAT with contents:write on the tap repo
#   VERSION           Release version (no leading 'v')
#   GITHUB_REPOSITORY_OWNER   Owner of the main repo (set by Actions)
#
# Skips quietly if GH_TOKEN is empty — releases without the tap secret
# configured still succeed; they just don't auto-update brew.
set -euo pipefail

if [[ -z "${GH_TOKEN:-}" ]]; then
    echo "HOMEBREW_TAP_TOKEN not set — skipping tap update."
    exit 0
fi

: "${VERSION:?VERSION required}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DMG="$ROOT/build/Mochi-${VERSION}.dmg"
[[ -f "$DMG" ]] || { echo "missing $DMG" >&2; exit 1; }

OWNER="${GITHUB_REPOSITORY_OWNER:-zekiahmetbayar}"
TAP_REPO="${OWNER}/homebrew-mochi"
SHA="$(shasum -a 256 "$DMG" | awk '{print $1}')"

echo "==> Updating ${TAP_REPO} → Mochi ${VERSION}"
echo "    sha256 = ${SHA}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

git clone --depth 1 \
    "https://x-access-token:${GH_TOKEN}@github.com/${TAP_REPO}.git" \
    "$WORK"

mkdir -p "$WORK/Casks"
cat > "$WORK/Casks/mochi.rb" <<EOF
cask "mochi" do
  version "${VERSION}"
  sha256 "${SHA}"

  url "https://github.com/${OWNER}/mochi/releases/download/v#{version}/Mochi-#{version}.dmg"
  name "Mochi"
  desc "Pixel-art companion that lives above your macOS menu bar"
  homepage "https://github.com/${OWNER}/mochi"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :ventura"

  app "Mochi.app"

  zap trash: [
    "~/Library/Preferences/com.zekiahmetbayar.mochi.plist",
    "~/Library/Application Support/Mochi",
  ]
end
EOF

cd "$WORK"
git config user.name  'mochi-release-bot'
git config user.email 'mochi-release-bot@users.noreply.github.com'

if git diff --quiet; then
    echo "==> Formula already up to date, nothing to push."
    exit 0
fi

git add Casks/mochi.rb
git commit -m "mochi ${VERSION}"
git push

echo "==> Tap updated."
