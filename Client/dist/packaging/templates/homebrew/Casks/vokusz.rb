# Review only: publication requires a DMG built with PACKAGE_MANAGER=true.
# Do not place updater markers inside the signed Vokusz.app bundle.
cask "vokusz" do
  version "@@VERSION@@"
  sha256 "@@MACOS_SHA256@@"

  url "https://github.com/ChunchunOwO/vokusz/releases/download/v#{version}/@@MACOS_ASSET@@"
  name "Vokusz"
  desc "Chat, voice, video, and screen sharing for Vokusz communities"
  homepage "https://github.com/ChunchunOwO/vokusz"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :catalina"
  app "Vokusz.app"

  uninstall quit: "com.vokusz.app"

  # Never delete Documents/vokusz/data: it contains accounts and messages.
  zap trash: "~/Library/Caches/com.vokusz.app"
end
