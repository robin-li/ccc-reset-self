# ccc-reset-self — Dev Notes

## 核心理念

CCC session 無法自己清除 context。唯一方式：kill process → wrapper 自動重啟。

本專案讓 CCC bot 透過 CLAUDE.md 指引，辨識 `#reset` / `#stop` → 自己 kill 自己 → wrapper 處理重啟。

**沒有 monitor daemon、沒有輪詢、沒有中間人。**

## 架構

```
用戶 (TG) → #reset → CCC bot → kill $PPID → ccc-wrapper.sh 偵測退出 → 重啟
用戶 (TG) → #stop  → CCC bot → touch .stop + kill $PPID → wrapper 退出
```

## 檔案說明

| 檔案 | 用途 |
|------|------|
| `bin/ccc-wrapper.sh` | 自動重啟迴圈，偵測 .stop 決定是否繼續 |
| `claude-md-snippet.md` | 貼進 CCC 工作目錄 CLAUDE.md 的指引片段 |
| `install.sh` | 一鍵安裝（複製檔案 + 建立 launchd 服務） |
| `uninstall.sh` | 一鍵移除 |
| `get.sh` | 遠端一鍵安裝（curl pipe bash） |

## 關鍵設計決策

1. **CCC bot 用 `kill $PPID`**：殺掉 wrapper 的子進程（自己），wrapper 偵測退出碼後重啟
2. **Stop 用 flag 檔案**：因為 wrapper 需要知道「這次不要重啟」，所以 stop 時先 touch .stop
3. **先回覆再 kill**：kill 之後什麼都不會執行，所以確認訊息必須先送出
4. **wrapper 啟動時清 .stop**：避免上次 stop 的殘留 flag 影響重啟
