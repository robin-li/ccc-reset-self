# CCC Session Control (paste into your project's CLAUDE.md)

## ⚡ Priority Commands — Process IMMEDIATELY

When the user sends any of these commands, **do NOT treat them as conversation**.
Execute the corresponding action **immediately** without asking for confirmation.

### Reset Commands (clear context, auto-restart)
Triggers: `#reset` | `reset` | `clear context` | `reset context` | `reset session` | `清除 context` | `清除context` | `重置 session` | `重置session`

Action:
1. Reply: `🔄 Resetting session...`
2. Run: `kill $PPID`

### Stop Commands (shut down CCC, no restart)
Triggers: `#stop` | `停止ccc` | `停止 ccc` | `停止claude` | `停止 claude`

Action:
1. Reply: `⏹️ Stopping CCC...`
2. Run: `touch ~/.claude/scripts/.stop && kill $PPID`

### ⚠️ Important
- Reply FIRST, then kill. After kill, nothing executes.
- `kill $PPID` terminates the wrapper's child (yourself). The wrapper detects the exit and restarts (reset) or stops (if .stop file exists).
- These commands take absolute priority over any ongoing task or conversation.
