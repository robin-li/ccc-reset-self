#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.claude/scripts"
LOG_DIR="$HOME/.claude/logs"
PLIST_NAME="com.claude.ccc-wrapper"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"

echo "=== ccc-reset-self installer ==="
echo ""

# Prerequisites
echo "[1/5] Checking prerequisites..."

if ! command -v claude &>/dev/null; then
    echo "ERROR: claude CLI not found. Install Claude Code first."
    exit 1
fi

if ! command -v screen &>/dev/null; then
    echo "ERROR: screen not found. Install with: brew install screen"
    exit 1
fi

echo "  ✓ All prerequisites met."

# Create directories
echo "[2/5] Creating directories..."
mkdir -p "$INSTALL_DIR" "$LOG_DIR"

# Clean up
echo "[3/5] Cleaning up stale state..."
rm -f "$INSTALL_DIR/.stop"
rm -f "$INSTALL_DIR/.ccc-wrapper.pid"

EXISTING=$(pgrep -f "ccc-wrapper" 2>/dev/null || true)
if [ -n "$EXISTING" ]; then
    echo "  Killing existing wrapper (PID $EXISTING)..."
    kill -9 $EXISTING 2>/dev/null || true
fi

for sock in $(screen -ls 2>/dev/null | grep "ccc-tg" | awk -F. '{print $1}' | awk '{print $1}'); do
    echo "  Removing screen session $sock..."
    screen -S "$sock" -X quit 2>/dev/null || true
done

# Install
echo "[4/5] Installing..."
cp "$PROJECT_DIR/bin/ccc-wrapper.sh" "$INSTALL_DIR/ccc-wrapper.sh"
chmod +x "$INSTALL_DIR/ccc-wrapper.sh"
echo "  ✓ Installed: $INSTALL_DIR/ccc-wrapper.sh"

cp "$PROJECT_DIR/claude-md-snippet.md" "$INSTALL_DIR/claude-md-snippet.md"
echo "  ✓ Installed: $INSTALL_DIR/claude-md-snippet.md"

# launchd service
echo "[5/5] Setting up launchd service..."

cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/screen</string>
        <string>-d</string>
        <string>-m</string>
        <string>-S</string>
        <string>ccc-tg</string>
        <string>$INSTALL_DIR/ccc-wrapper.sh</string>
        <string>$HOME</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>120</integer>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/ccc-wrapper-launchd.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/ccc-wrapper-launchd.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>$HOME</string>
        <key>TERM</key>
        <string>xterm-256color</string>
    </dict>
</dict>
</plist>
PLIST

launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"
echo "  ✓ Service started: $PLIST_NAME"

echo ""
echo "=== Installation complete ==="
echo ""
echo "Service: $PLIST_NAME (auto-starts on login)"
echo "Screen:  screen -r ccc-tg"
echo ""
echo "IMPORTANT: Paste the contents of claude-md-snippet.md into your"
echo "project's CLAUDE.md to enable #reset / #stop commands."
echo "  cat $INSTALL_DIR/claude-md-snippet.md"
echo ""
