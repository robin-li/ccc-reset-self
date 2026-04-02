#!/bin/bash
set -e

INSTALL_DIR="$HOME/.claude/scripts"
PLIST_NAME="com.claude.ccc-wrapper"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"

echo "=== ccc-reset-self uninstaller ==="
echo ""

echo "[1/3] Stopping service..."
if [ -f "$PLIST_PATH" ]; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm -f "$PLIST_PATH"
    echo "  ✓ Removed: $PLIST_PATH"
fi

screen -S ccc-tg -X quit 2>/dev/null || true

echo "[2/3] Removing files..."
for f in ccc-wrapper.sh claude-md-snippet.md .ccc-wrapper.pid .stop; do
    if [ -f "$INSTALL_DIR/$f" ]; then
        rm -f "$INSTALL_DIR/$f"
        echo "  ✓ Removed: $INSTALL_DIR/$f"
    fi
done

echo "[3/3] Cleaning up..."
screen -wipe 2>/dev/null || true

echo ""
echo "=== Uninstallation complete ==="
echo ""
echo "Note: Remember to remove the CCC Session Control section from your CLAUDE.md."
echo ""
