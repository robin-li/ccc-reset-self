# ccc-reset-self — Dev Notes

## 核心理念

CCC session 無法自己清除 context。唯一方式：kill process → wrapper 自動重啟。

本專案讓 CCC bot 透過 CLAUDE.md 指引，辨識 `#reset` / `#stop` → 自己 kill 自己 → wrapper 處理重啟。

**沒有 monitor daemon、沒有輪詢、沒有中間人。**

## 架構

```
用戶 (TG) → #reset → CCC bot touch .reset → wrapper 偵測 flag → kill claude → 重啟
用戶 (TG) → #stop  → CCC bot touch .stop  → wrapper 偵測 flag → kill claude → 退出
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

1. **CCC bot 只 touch flag**：不負責 kill，職責分離乾淨
2. **Wrapper 負責所有 process 管理**：背景 monitor 每 2 秒查 flag → kill claude 子進程
3. **Reset = 刪 flag + kill → wrapper 迴圈重啟**
4. **Stop = 留 flag + kill → wrapper 偵測 .stop 後退出**
5. **wrapper 啟動時清 flag**：避免殘留 flag 影響重啟
