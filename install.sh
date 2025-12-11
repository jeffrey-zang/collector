#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNNER_SOURCE="$SCRIPT_DIR/collection-runner.sh"
RUNNER_TARGET="/usr/local/bin/collection-runner.sh"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$PLIST_DIR/dev.jeffz.collection-runner.plist"

if [ ! -f "$RUNNER_SOURCE" ]; then
  echo "collection-runner.sh not found at $RUNNER_SOURCE" >&2
  exit 1
fi

mkdir -p "$PLIST_DIR"

cp "$RUNNER_SOURCE" "$RUNNER_TARGET"
chmod +x "$RUNNER_TARGET"

cat >"$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>dev.jeffz.collection-runner</string>

  <key>ProgramArguments</key>
  <array>
    <string>$RUNNER_TARGET</string>
  </array>

  <key>RunAtLoad</key>
  <true/>

  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
EOF

if launchctl list | grep -q "dev.jeffz.collection-runner"; then
  launchctl unload "$PLIST_PATH" 2>/dev/null || true
fi

launchctl load "$PLIST_PATH"

echo "Installed collection-runner to $RUNNER_TARGET"
echo "LaunchAgent written to $PLIST_PATH and loaded via launchctl"
