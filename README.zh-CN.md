# ccc-reset-self

> 通过 Telegram 消息重置或停止 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 会话。无需额外的监控进程。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)]()
[![Python: Not Required](https://img.shields.io/badge/Python-不需要-green.svg)]()
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-4EAA25.svg)]()

[English](README.md) | [繁體中文](README.zh-TW.md) | **简体中文** | [Tiếng Việt](README.vi.md) | [ภาษาไทย](README.th.md)

---

## 问题

通过 [Telegram 插件](https://github.com/anthropics/claude-code-plugins) 运行的 Claude Code Channel（CCC）会话无法自行清除对话上下文。当上下文窗口填满时，响应质量会下降——唯一的解决办法是终止进程并重新启动。

## 解决方案

**ccc-reset-self** 采用极简方法：

1. 通过 `CLAUDE.md` 指引教 CCC bot 识别 `#reset` / `#stop` 命令
2. Bot 只创建一个 flag 文件——仅此而已
3. 轻量的 wrapper 脚本检测到 flag 后，终止进程并以全新会话重新启动

不需要 Python。不需要轮询守护进程。不需要外部监控。只需一个 shell 脚本和一个 markdown 文件。

## 架构

```
┌─────────────┐     #reset      ┌─────────────────┐
│  Telegram    │ ──────────────▶ │   CCC Bot       │
│  (用户)       │                 │  (Claude Code)   │
└─────────────┘                  └────────┬────────┘
                                          │ touch .reset
                                          ▼
                                 ┌─────────────────┐
                                 │  .reset / .stop  │  ← flag 文件
                                 └────────┬────────┘
                                          │ 检测 (每 2 秒)
                                          ▼
                                 ┌─────────────────┐
                                 │  ccc-wrapper.sh  │
                                 │  (flag 监控)      │──▶ 终止 claude
                                 │  (重启循环)       │──▶ 重新启动
                                 └─────────────────┘
```

**职责分离：**
- **CCC bot** — 识别命令，创建 flag 文件。不负责终止任何进程。
- **Wrapper** — 管理所有进程生命周期：监控 flag、终止 Claude、重启或退出。

## 前置要求

- **macOS**（使用 `launchd` 管理服务）
- **[Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)** 已安装
- **[Telegram 插件](https://github.com/anthropics/claude-code-plugins)** 已配置
- **`screen`**（`brew install screen`）

## 安装

### 快速安装（一键命令）

```bash
curl -fsSL https://raw.githubusercontent.com/robin-li/ccc-reset-self/main/get.sh | bash
```

### 从源码安装

```bash
git clone https://github.com/robin-li/ccc-reset-self.git
cd ccc-reset-self
./install.sh
```

安装程序会：
1. 复制 `ccc-wrapper.sh` 到 `~/.claude/scripts/`
2. 将命令说明注入 `~/.claude/CLAUDE.md`（全局生效，适用所有会话）
3. 注册 `launchd` 服务，登录时自动启动

## 使用方式

### Telegram 命令

向你的 CCC bot 发送以下消息：

| 命令 | 动作 | 行为 |
|------|------|------|
| `#reset` | 重置会话 | Bot 回复 → 创建 `.reset` → wrapper 终止并重启 |
| `reset` | 重置会话 | 同上 |
| `clear context` | 重置会话 | 同上 |
| `清除 context` | 重置会话 | 同上 |
| `重置 session` | 重置会话 | 同上 |
| `#stop` | 停止 CCC | Bot 回复 → 创建 `.stop` → wrapper 终止并退出 |
| `停止ccc` | 停止 CCC | 同上 |
| `停止claude` | 停止 CCC | 同上 |

### 手动控制（终端 / SSH）

```bash
# 手动启动 wrapper
~/.claude/scripts/ccc-wrapper.sh ~/workspace --model sonnet

# 使用其他模型
~/.claude/scripts/ccc-wrapper.sh ~/workspace --model opus

# 连接到 screen 会话
screen -r ccc-tg

# 手动触发重置
touch ~/.claude/scripts/.reset

# 手动触发停止
touch ~/.claude/scripts/.stop
```

### 服务管理

```bash
# 检查服务状态
launchctl list | grep ccc-wrapper

# 重启服务
launchctl unload ~/Library/LaunchAgents/com.claude.ccc-wrapper.plist
launchctl load ~/Library/LaunchAgents/com.claude.ccc-wrapper.plist

# 查看日志
tail -f ~/.claude/logs/ccc-wrapper.log
```

## 工作原理

### 重置流程

```
1. 用户在 Telegram 发送 "#reset"
2. CCC bot 识别命令（通过 CLAUDE.md 指引）
3. CCC bot 回复「🔄 Resetting session...」
4. CCC bot 执行：touch ~/.claude/scripts/.reset
5. Wrapper 的 flag 监控检测到 .reset（2 秒内）
6. Wrapper 终止 Claude 进程
7. Wrapper 等待 3 秒，然后启动新的 Claude 会话
```

### 停止流程

```
1. 用户在 Telegram 发送 "#stop"
2. CCC bot 识别命令（通过 CLAUDE.md 指引）
3. CCC bot 回复「⏹️ Stopping CCC...」
4. CCC bot 执行：touch ~/.claude/scripts/.stop
5. Wrapper 的 flag 监控检测到 .stop（2 秒内）
6. Wrapper 终止 Claude 进程
7. Wrapper 检测到 .stop flag → 退出（不重启）
```

## 卸载

```bash
# 从 clone 的 repo
cd ccc-reset-self
./uninstall.sh

# 或远程一键命令
curl -fsSL https://raw.githubusercontent.com/robin-li/ccc-reset-self/main/uninstall.sh | bash
```

会移除 wrapper 脚本、`launchd` 服务，以及从 `~/.claude/CLAUDE.md` 中注入的部分。

## 常见问题

**Q: 如果 CCC bot 没有识别到命令怎么办？**
A: 指引放在 `~/.claude/CLAUDE.md` 中，具有高优先级。Claude Code 启动时会读取此文件。实际使用中能可靠识别触发词。若未识别，可使用手动方式：`touch ~/.claude/scripts/.reset`

**Q: 可以自定义触发命令吗？**
A: 可以。编辑 `~/.claude/CLAUDE.md` 中的 `# CCC Session Control` 部分，添加或修改触发词。

**Q: 支持 Linux 吗？**
A: Wrapper 脚本可在任何 Unix 系统运行。`install.sh` 使用 macOS `launchd` 自动启动。在 Linux 上需自行配置 `systemd` 服务或修改安装脚本。

**Q: 重置要多久？**
A: Flag 监控每 2 秒检查一次，加上 3 秒重启延迟。总计约 5 秒从发送命令到全新会话就绪。

## 许可证

[MIT](LICENSE)
