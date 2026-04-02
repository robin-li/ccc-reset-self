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
for f in ccc-wrapper.sh .ccc-wrapper.pid .stop; do
    if [ -f "$INSTALL_DIR/$f" ]; then
        rm -f "$INSTALL_DIR/$f"
        echo "  ✓ Removed: $INSTALL_DIR/$f"
    fi
done

# Remove snippet from ~/.claude/CLAUDE.md
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
if [ -f "$CLAUDE_MD" ] && grep -qF "# CCC Session Control" "$CLAUDE_MD"; then
    # Remove from marker to end of snippet (blank line before next section or EOF)
    sed -i '' '/^# CCC Session Control/,/^# [^C]/{ /^# [^C]/!d; }' "$CLAUDE_MD" 2>/dev/null || true
    # Clean up: remove trailing blank lines
    sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$CLAUDE_MD" 2>/dev/null || true
    echo "  ✓ Removed CCC Session Control from $CLAUDE_MD"
fi

echo "[3/3] Cleaning up..."
screen -wipe 2>/dev/null || true

echo ""
echo "=== Uninstallation complete ==="
echo ""
echo "CCC Session Control has been fully removed."
echo ""
