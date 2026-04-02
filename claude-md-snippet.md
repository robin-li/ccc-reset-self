# CCC Session Control (auto-injected by ccc-reset-self)

## ⚡ Priority Commands — Process IMMEDIATELY

When the user sends any of these commands, **do NOT treat them as conversation**.
Execute the corresponding action **immediately** without asking for confirmation.

### Reset Commands (clear context, auto-restart)
Triggers: `#reset` | `reset` | `clear context` | `reset context` | `reset session` | `清除 context` | `清除context` | `重置 session` | `重置session`

Action:
1. Reply: `🔄 Resetting session...`
2. Run: `touch ~/.claude/scripts/.reset`

### Stop Commands (shut down CCC, no restart)
Triggers: `#stop` | `停止ccc` | `停止 ccc` | `停止claude` | `停止 claude`

Action:
1. Reply: `⏹️ Stopping CCC...`
2. Run: `touch ~/.claude/scripts/.stop`

### ⚠️ Important
- These commands take absolute priority over any ongoing task or conversation.
- Just touch the flag file. The wrapper handles the rest (kill + restart or exit).
