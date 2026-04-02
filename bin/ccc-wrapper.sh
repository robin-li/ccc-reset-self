#!/bin/bash
#
# CCC Wrapper — auto-restart loop for Claude Code Channel
#
# Usage: ccc-wrapper.sh [working_directory] [--model MODEL]
#
# Stop: CCC bot touches ~/.claude/scripts/.stop then exits
# Resume: rm ~/.claude/scripts/.stop && run this script again

CLAUDE_BIN="$(command -v claude 2>/dev/null || echo "$HOME/.local/bin/claude")"
SCRIPTS_DIR="$HOME/.claude/scripts"
STOP_FILE="$SCRIPTS_DIR/.stop"
LOG_DIR="$HOME/.claude/logs"
LOG_FILE="$LOG_DIR/ccc-wrapper.log"
PID_FILE="$SCRIPTS_DIR/.ccc-wrapper.pid"

WORK_DIR="$HOME"
MODEL="sonnet"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --model)
            MODEL="$2"
            shift 2
            ;;
        *)
            WORK_DIR="$1"
            shift
            ;;
    esac
done

mkdir -p "$LOG_DIR" "$SCRIPTS_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Prevent multiple wrapper instances
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        log "Wrapper already running (PID $OLD_PID). Exiting."
        exit 0
    else
        log "Stale PID file (PID $OLD_PID). Removing."
        rm -f "$PID_FILE"
    fi
fi

echo $$ > "$PID_FILE"
trap "rm -f '$PID_FILE'" EXIT

# Clear stale stop file on fresh start
rm -f "$STOP_FILE"

log "CCC Wrapper started (PID $$)"
log "  Working directory: $WORK_DIR"
log "  Model: $MODEL"
log "  Claude binary: $CLAUDE_BIN"

while true; do
    if [ -f "$STOP_FILE" ]; then
        log "Stop file detected. Exiting wrapper."
        rm -f "$STOP_FILE"
        exit 0
    fi

    log "Starting Claude Code..."
    cd "$WORK_DIR" || exit 1

    "$CLAUDE_BIN" \
        --dangerously-skip-permissions \
        --channels plugin:telegram@claude-plugins-official \
        --model "$MODEL"

    EXIT_CODE=$?
    log "Claude Code exited (code $EXIT_CODE)"

    if [ -f "$STOP_FILE" ]; then
        log "Stop file detected after exit. Exiting wrapper."
        rm -f "$STOP_FILE"
        exit 0
    fi

    log "Restarting in 3 seconds..."
    sleep 3
done
