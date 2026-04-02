# ccc-reset-self

> 透過 Telegram 訊息重置或停止 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 會話。無需額外的監控程式。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)]()
[![Python: Not Required](https://img.shields.io/badge/Python-不需要-green.svg)]()
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-4EAA25.svg)]()

[English](README.md) | **繁體中文** | [简体中文](README.zh-CN.md) | [Tiếng Việt](README.vi.md) | [ภาษาไทย](README.th.md)

---

## 問題

透過 [Telegram 外掛](https://github.com/anthropics/claude-code-plugins) 運行的 Claude Code Channel（CCC）會話無法自行清除對話上下文。當上下文視窗填滿時，回應品質會下降——唯一的解決辦法是終止程序並重新啟動。

## 解決方案

**ccc-reset-self** 採用極簡方法：

1. 透過 `CLAUDE.md` 指引教 CCC bot 辨識 `#reset` / `#stop` 指令
2. Bot 只建立一個 flag 檔案——僅此而已
3. 輕量的 wrapper 腳本偵測到 flag 後，終止程序並以全新會話重新啟動

不需要 Python。不需要輪詢守護程式。不需要外部監控。只需一個 shell 腳本和一個 markdown 檔案。

## 架構

```
┌─────────────┐     #reset      ┌─────────────────┐
│  Telegram    │ ──────────────▶ │   CCC Bot       │
│  (使用者)     │                 │  (Claude Code)   │
└─────────────┘                  └────────┬────────┘
                                          │ touch .reset
                                          ▼
                                 ┌─────────────────┐
                                 │  .reset / .stop  │  ← flag 檔案
                                 └────────┬────────┘
                                          │ 偵測 (每 2 秒)
                                          ▼
                                 ┌─────────────────┐
                                 │  ccc-wrapper.sh  │
                                 │  (flag 監控)      │──▶ 終止 claude
                                 │  (重啟迴圈)       │──▶ 重新啟動
                                 └─────────────────┘
```

**職責分離：**
- **CCC bot** — 辨識指令，建立 flag 檔案。不負責終止任何程序。
- **Wrapper** — 管理所有程序生命週期：監控 flag、終止 Claude、重啟或退出。

## 前置需求

- **macOS**（使用 `launchd` 管理服務）
- **[Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)** 已安裝
- **[Telegram 外掛](https://github.com/anthropics/claude-code-plugins)** 已設定
- **`screen`**（`brew install screen`）

## 安裝

### 快速安裝（一鍵指令）

```bash
curl -fsSL https://raw.githubusercontent.com/robin-li/ccc-reset-self/main/get.sh | bash
```

### 從原始碼安裝

```bash
git clone https://github.com/robin-li/ccc-reset-self.git
cd ccc-reset-self
./install.sh
```

安裝程式會：
1. 複製 `ccc-wrapper.sh` 到 `~/.claude/scripts/`
2. 將指令說明注入 `~/.claude/CLAUDE.md`（全域生效，適用所有會話）
3. 註冊 `launchd` 服務，登入時自動啟動

## 使用方式

### Telegram 指令

向你的 CCC bot 發送以下訊息：

| 指令 | 動作 | 行為 |
|------|------|------|
| `#reset` | 重置會話 | Bot 回覆 → 建立 `.reset` → wrapper 終止並重啟 |
| `reset` | 重置會話 | 同上 |
| `clear context` | 重置會話 | 同上 |
| `清除 context` | 重置會話 | 同上 |
| `重置 session` | 重置會話 | 同上 |
| `#stop` | 停止 CCC | Bot 回覆 → 建立 `.stop` → wrapper 終止並退出 |
| `停止ccc` | 停止 CCC | 同上 |
| `停止claude` | 停止 CCC | 同上 |

### 手動控制（終端 / SSH）

```bash
# 手動啟動 wrapper
~/.claude/scripts/ccc-wrapper.sh ~/workspace --model sonnet

# 使用其他模型
~/.claude/scripts/ccc-wrapper.sh ~/workspace --model opus

# 連接到 screen 會話
screen -r ccc-tg

# 手動觸發重置
touch ~/.claude/scripts/.reset

# 手動觸發停止
touch ~/.claude/scripts/.stop
```

### 服務管理

```bash
# 檢查服務狀態
launchctl list | grep ccc-wrapper

# 重啟服務
launchctl unload ~/Library/LaunchAgents/com.claude.ccc-wrapper.plist
launchctl load ~/Library/LaunchAgents/com.claude.ccc-wrapper.plist

# 查看日誌
tail -f ~/.claude/logs/ccc-wrapper.log
```

## 運作原理

### 重置流程

```
1. 使用者在 Telegram 發送 "#reset"
2. CCC bot 辨識指令（透過 CLAUDE.md 指引）
3. CCC bot 回覆「🔄 Resetting session...」
4. CCC bot 執行：touch ~/.claude/scripts/.reset
5. Wrapper 的 flag 監控偵測到 .reset（2 秒內）
6. Wrapper 終止 Claude 程序
7. Wrapper 等待 3 秒，然後啟動新的 Claude 會話
```

### 停止流程

```
1. 使用者在 Telegram 發送 "#stop"
2. CCC bot 辨識指令（透過 CLAUDE.md 指引）
3. CCC bot 回覆「⏹️ Stopping CCC...」
4. CCC bot 執行：touch ~/.claude/scripts/.stop
5. Wrapper 的 flag 監控偵測到 .stop（2 秒內）
6. Wrapper 終止 Claude 程序
7. Wrapper 偵測到 .stop flag → 退出（不重啟）
```

## 解除安裝

```bash
# 從 clone 的 repo
cd ccc-reset-self
./uninstall.sh

# 或遠端一鍵指令
curl -fsSL https://raw.githubusercontent.com/robin-li/ccc-reset-self/main/uninstall.sh | bash
```

會移除 wrapper 腳本、`launchd` 服務，以及從 `~/.claude/CLAUDE.md` 中注入的區段。

## 常見問題

**Q: 如果 CCC bot 沒有辨識到指令怎麼辦？**
A: 指引放在 `~/.claude/CLAUDE.md` 中，具有高優先級。Claude Code 啟動時會讀取此檔案。實際使用中能可靠辨識觸發詞。若未辨識，可使用手動方式：`touch ~/.claude/scripts/.reset`

**Q: 可以自訂觸發指令嗎？**
A: 可以。編輯 `~/.claude/CLAUDE.md` 中的 `# CCC Session Control` 區段，新增或修改觸發詞。

**Q: 支援 Linux 嗎？**
A: Wrapper 腳本可在任何 Unix 系統運行。`install.sh` 使用 macOS `launchd` 自動啟動。在 Linux 上需自行設定 `systemd` 服務或調整安裝腳本。

**Q: 重置要多久？**
A: Flag 監控每 2 秒檢查一次，加上 3 秒重啟延遲。總計約 5 秒從發送指令到全新會話就緒。

## 授權

[MIT](LICENSE)
