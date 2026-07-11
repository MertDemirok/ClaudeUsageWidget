cask "claude-usage-widget" do
  version "1.0.0"
  sha256 "PLACEHOLDER"

  url "https://github.com/mertdemirok/ClaudeUsageWidget/releases/download/v#{version}/ClaudeUsageWidget.zip"
  name "Claude Usage Widget"
  desc "macOS menu bar app to track Claude AI usage"
  homepage "https://github.com/mertdemirok/ClaudeUsageWidget"

  app "ClaudeUsageWidget.app"

  zap trash: [
    "~/Library/Application Support/com.checkyourailimit.ClaudeUsageWidget",
    "~/Library/Preferences/com.checkyourailimit.ClaudeUsageWidget.plist",
  ]
end
