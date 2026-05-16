cask "mochi" do
  version "0.0.0"
  sha256 :no_check

  url "https://github.com/zekiahmetbayar/mochi/releases/download/v#{version}/Mochi-#{version}.dmg"
  name "Mochi"
  desc "Pixel-art companion that lives above your macOS menu bar"
  homepage "https://github.com/zekiahmetbayar/mochi"

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
