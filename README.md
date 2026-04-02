# ccc-reset-self

> Reset or stop Claude Code Channel (CCC) via Telegram commands — no external monitor needed.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)]()

Claude Code sessions can't clear their own context. The only way to get a fresh session is to kill the process and restart. This project provides a minimal wrapper + CLAUDE.md instructions that let CCC handle `#reset` and `#stop` commands by terminating itself — the wrapper then restarts automatically.

## How It Works

```
User sends #reset → CCC bot recognizes command → replies "🔄 Resetting..."
→ runs kill $PPID → wrapper detects exit → restarts fresh session
```

**Two components, zero daemons:**

1. **`ccc-wrapper.sh`** — runs Claude Code in a loop. If the process exits, it restarts in 3 seconds. If `.stop` file exists, it exits instead.
2. **`claude-md-snippet.md`** — instructions for CCC bot to recognize `#reset` / `#stop` and self-terminate. Paste into your project's CLAUDE.md.

No polling daemon. No monitor process. CCC kills itself, the wrapper does the rest.

## Installation

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/robin-li/ccc-reset-self/main/get.sh | bash
```

### From source

```bash
git clone https://github.com/robin-li/ccc-reset-self.git
cd ccc-reset-self
./install.sh
```

### After install

**Important:** Paste the snippet into your project's CLAUDE.md:

```bash
cat ~/.claude/scripts/claude-md-snippet.md >> ~/your-project/CLAUDE.md
```

## Usage

### Telegram Commands

| Command | Action |
|---------|--------|
| `#reset` / `reset` / `clear context` / `重置 session` | Reset session (auto-restart) |
| `#stop` / `停止ccc` / `停止claude` | Stop CCC (no restart) |

### Manual (terminal / SSH)

```bash
# Start wrapper
~/.claude/scripts/ccc-wrapper.sh ~/workspace --model sonnet

# Start with custom model
~/.claude/scripts/ccc-wrapper.sh ~/workspace --model opus
```

### Attach to session

```bash
screen -r ccc-tg
```

## Uninstall

```bash
cd ccc-reset-self
./uninstall.sh
```

Or:

```bash
curl -fsSL https://raw.githubusercontent.com/robin-li/ccc-reset-self/main/uninstall.sh | bash
```

## Project Structure

```
ccc-reset-self/
├── bin/
│   └── ccc-wrapper.sh       # Auto-restart wrapper
├── claude-md-snippet.md      # CLAUDE.md instructions for #reset / #stop
├── get.sh                    # One-liner remote installer
├── install.sh                # Installer (launchd + files)
├── uninstall.sh              # Uninstaller
├── README.md
├── CLAUDE.md                 # Dev notes
└── LICENSE
```

## License

[MIT](LICENSE)
