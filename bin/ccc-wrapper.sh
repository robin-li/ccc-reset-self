#!/bin/bash
#
# CCC Wrapper — auto-restart loop for Claude Code Channel
#
# Usage: ccc-wrapper.sh [working_directory] [--model MODEL]
#
# CCC bot touches flag files, this wrapper handles kill + restart.

CLAUDE_BIN="$(command -v claude 2>/dev/null || echo "$HOME/.local/bin/claude")"
SCRIPTS_DIR="$HOME/.claude/scripts"
STOP_FILE="$SCRIPTS_DIR/.stop"
RESET_FILE="$SCRIPTS_DIR/.reset"
LOG_DIR="$HOME/.claude/logs"
LOG_FILE="$LOG_DIR/ccc-wrapper.log"
PID_FILE="$SCRIPTS_DIR/.ccc-wrapper.pid"

WORK_DIR="$HOME"
MODEL="sonnet"
CLAUDE_PID=""
MONITOR_PID=""

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

cleanup() {
    # Kill monitor and claude on wrapper exit
    [ -n "$MONITOR_PID" ] && kill "$MONITOR_PID" 2>/dev/null
    [ -n "$CLAUDE_PID" ] && kill "$CLAUDE_PID" 2>/dev/null
    rm -f "$PID_FILE" "$RESET_FILE"
}
trap cleanup EXIT

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

# Clear stale flags on fresh start
rm -f "$STOP_FILE" "$RESET_FILE"

log "CCC Wrapper started (PID $$)"
log "  Working directory: $WORK_DIR"
log "  Model: $MODEL"
log "  Claude binary: $CLAUDE_BIN"

# Background flag monitor — watches for .reset / .stop and kills claude
start_flag_monitor() {
    (
        while true; do
            sleep 2

            # Stop signal
            if [ -f "$STOP_FILE" ]; then
                log "[monitor] Stop flag detected."
                rm -f "$RESET_FILE"
                [ -n "$CLAUDE_PID" ] && kill "$CLAUDE_PID" 2>/dev/null
                break
            fi

            # Reset signal
            if [ -f "$RESET_FILE" ]; then
                log "[monitor] Reset flag detected."
                rm -f "$RESET_FILE"
                [ -n "$CLAUDE_PID" ] && kill "$CLAUDE_PID" 2>/dev/null
            fi
        done
    ) &
    MONITOR_PID=$!
}

while true; do
    if [ -f "$STOP_FILE" ]; then
        log "Stop file detected. Exiting wrapper."
        rm -f "$STOP_FILE"
        exit 0
    fi

    log "Starting Claude Code..."
    cd "$WORK_DIR" || exit 1

    # Start flag monitor
    start_flag_monitor

    "$CLAUDE_BIN" \
        --dangerously-skip-permissions \
        --channels plugin:telegram@claude-plugins-official \
        --model "$MODEL" &
    CLAUDE_PID=$!

    # Wait for claude to exit (killed by monitor or crashed)
    wait "$CLAUDE_PID" 2>/dev/null
    EXIT_CODE=$?
    CLAUDE_PID=""

    # Stop flag monitor for this iteration
    [ -n "$MONITOR_PID" ] && kill "$MONITOR_PID" 2>/dev/null
    MONITOR_PID=""

    log "Claude Code exited (code $EXIT_CODE)"

    if [ -f "$STOP_FILE" ]; then
        log "Stop file detected after exit. Exiting wrapper."
        rm -f "$STOP_FILE"
        exit 0
    fi

    log "Restarting in 3 seconds..."
    sleep 3
done
