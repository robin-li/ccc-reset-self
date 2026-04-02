# ccc-reset-self

> รีเซ็ตหรือหยุดเซสชัน [Claude Code](https://docs.anthropic.com/en/docs/claude-code) ผ่าน Telegram ด้วยข้อความเดียว ไม่ต้องใช้ daemon ตรวจสอบภายนอก

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)]()
[![Python: Not Required](https://img.shields.io/badge/Python-ไม่ต้องใช้-green.svg)]()
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-4EAA25.svg)]()

[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md) | [Tiếng Việt](README.vi.md) | **ภาษาไทย**

---

## ปัญหา

เซสชัน Claude Code Channel (CCC) ที่ทำงานผ่าน [ปลั๊กอิน Telegram](https://github.com/anthropics/claude-code-plugins) ไม่มีวิธีในตัวเพื่อล้างบริบทการสนทนา เมื่อหน้าต่างบริบทเต็ม คุณภาพการตอบกลับจะลดลง — วิธีแก้ไขเดียวคือยุติโปรเซสและเริ่มต้นใหม่

## วิธีแก้ไข

**ccc-reset-self** ใช้แนวทางที่เรียบง่ายที่สุด:

1. สอน CCC bot ให้จำคำสั่ง `#reset` / `#stop` ผ่านคำแนะนำใน `CLAUDE.md`
2. Bot สร้างไฟล์ flag เท่านั้น — แค่นั้น
3. Wrapper script ตรวจพบ flag แล้วยุติโปรเซสและเริ่มใหม่ด้วยเซสชันใหม่

ไม่ต้องใช้ Python ไม่ต้องใช้ polling daemon ไม่ต้องใช้ monitor ภายนอก แค่ shell script หนึ่งไฟล์กับ markdown หนึ่งไฟล์

## สถาปัตยกรรม

```
┌─────────────┐     #reset      ┌─────────────────┐
│  Telegram    │ ──────────────▶ │   CCC Bot       │
│  (ผู้ใช้)     │                 │  (Claude Code)   │
└─────────────┘                  └────────┬────────┘
                                          │ touch .reset
                                          ▼
                                 ┌─────────────────┐
                                 │  .reset / .stop  │  ← ไฟล์ flag
                                 └────────┬────────┘
                                          │ ตรวจจับ (ทุก 2 วินาที)
                                          ▼
                                 ┌─────────────────┐
                                 │  ccc-wrapper.sh  │
                                 │  (ตรวจสอบ flag)  │──▶ ยุติ claude
                                 │  (วนลูป)         │──▶ เริ่มใหม่
                                 └─────────────────┘
```

**แบ่งแยกหน้าที่:**
- **CCC bot** — จำคำสั่ง, สร้างไฟล์ flag ไม่ยุติโปรเซสใดๆ
- **Wrapper** — จัดการวงจรชีวิตโปรเซสทั้งหมด: ตรวจสอบ flag, ยุติ Claude, เริ่มใหม่หรือออก

## ความต้องการ

- **macOS** (ใช้ `launchd` จัดการบริการ)
- **[Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)** ติดตั้งแล้ว
- **[ปลั๊กอิน Telegram](https://github.com/anthropics/claude-code-plugins)** กำหนดค่าแล้ว
- **`screen`** (`brew install screen`)

## การติดตั้ง

### ติดตั้งด่วน (คำสั่งเดียว)

```bash
curl -fsSL https://raw.githubusercontent.com/robin-li/ccc-reset-self/main/get.sh | bash
```

### ติดตั้งจากซอร์สโค้ด

```bash
git clone https://github.com/robin-li/ccc-reset-self.git
cd ccc-reset-self
./install.sh
```

ตัวติดตั้งจะ:
1. คัดลอก `ccc-wrapper.sh` ไปยัง `~/.claude/scripts/`
2. เพิ่มคำแนะนำคำสั่งลงใน `~/.claude/CLAUDE.md` (ทั่วโลก, ใช้กับทุกเซสชัน)
3. ลงทะเบียนบริการ `launchd` ให้เริ่มอัตโนมัติเมื่อล็อกอิน

## การใช้งาน

### คำสั่ง Telegram

ส่งข้อความเหล่านี้ไปยัง CCC bot ของคุณ:

| คำสั่ง | การกระทำ | พฤติกรรม |
|--------|----------|----------|
| `#reset` | รีเซ็ตเซสชัน | Bot ตอบกลับ → สร้าง `.reset` → wrapper ยุติและเริ่มใหม่ |
| `reset` | รีเซ็ตเซสชัน | เช่นเดียวกัน |
| `clear context` | รีเซ็ตเซสชัน | เช่นเดียวกัน |
| `reset session` | รีเซ็ตเซสชัน | เช่นเดียวกัน |
| `清除 context` | รีเซ็ตเซสชัน | เช่นเดียวกัน |
| `重置 session` | รีเซ็ตเซสชัน | เช่นเดียวกัน |
| `#stop` | หยุด CCC | Bot ตอบกลับ → สร้าง `.stop` → wrapper ยุติและออก |
| `停止ccc` | หยุด CCC | เช่นเดียวกัน |
| `停止claude` | หยุด CCC | เช่นเดียวกัน |

### ควบคุมด้วยตนเอง (Terminal / SSH)

```bash
# เริ่ม wrapper ด้วยตนเอง
~/.claude/scripts/ccc-wrapper.sh ~/workspace --model sonnet

# ใช้โมเดลอื่น
~/.claude/scripts/ccc-wrapper.sh ~/workspace --model opus

# เชื่อมต่อเซสชัน screen
screen -r ccc-tg

# ทริกเกอร์ reset ด้วยตนเอง
touch ~/.claude/scripts/.reset

# ทริกเกอร์ stop ด้วยตนเอง
touch ~/.claude/scripts/.stop
```

### จัดการบริการ

```bash
# ตรวจสอบสถานะบริการ
launchctl list | grep ccc-wrapper

# เริ่มบริการใหม่
launchctl unload ~/Library/LaunchAgents/com.claude.ccc-wrapper.plist
launchctl load ~/Library/LaunchAgents/com.claude.ccc-wrapper.plist

# ดู log
tail -f ~/.claude/logs/ccc-wrapper.log
```

## วิธีการทำงาน

### ขั้นตอน Reset

```
1. ผู้ใช้ส่ง "#reset" บน Telegram
2. CCC bot จำคำสั่ง (ผ่านคำแนะนำ CLAUDE.md)
3. CCC bot ตอบ "🔄 Resetting session..."
4. CCC bot รัน: touch ~/.claude/scripts/.reset
5. Flag monitor ของ wrapper ตรวจพบ .reset (ภายใน 2 วินาที)
6. Wrapper ยุติโปรเซส Claude
7. Wrapper รอ 3 วินาที แล้วเริ่มเซสชัน Claude ใหม่
```

### ขั้นตอน Stop

```
1. ผู้ใช้ส่ง "#stop" บน Telegram
2. CCC bot จำคำสั่ง (ผ่านคำแนะนำ CLAUDE.md)
3. CCC bot ตอบ "⏹️ Stopping CCC..."
4. CCC bot รัน: touch ~/.claude/scripts/.stop
5. Flag monitor ของ wrapper ตรวจพบ .stop (ภายใน 2 วินาที)
6. Wrapper ยุติโปรเซส Claude
7. Wrapper ตรวจพบไฟล์ .stop → ออก (ไม่เริ่มใหม่)
```

## ถอนการติดตั้ง

```bash
# จาก repo ที่ clone มา
cd ccc-reset-self
./uninstall.sh

# หรือคำสั่งเดียวจากระยะไกล
curl -fsSL https://raw.githubusercontent.com/robin-li/ccc-reset-self/main/uninstall.sh | bash
```

จะลบ wrapper script, บริการ `launchd`, และส่วนที่เพิ่มใน `~/.claude/CLAUDE.md`

## คำถามที่พบบ่อย

**Q: ถ้า CCC bot ไม่จำคำสั่งล่ะ?**
A: คำแนะนำอยู่ใน `~/.claude/CLAUDE.md` ด้วยความสำคัญสูง Claude Code อ่านไฟล์นี้ตอนเริ่มต้น ในทางปฏิบัติ จำวลีทริกเกอร์ได้อย่างน่าเชื่อถือ ถ้าไม่ได้ ใช้วิธีด้วยตนเอง: `touch ~/.claude/scripts/.reset`

**Q: ปรับแต่งคำสั่งทริกเกอร์ได้ไหม?**
A: ได้ แก้ไขส่วน `# CCC Session Control` ใน `~/.claude/CLAUDE.md` เพื่อเพิ่มหรือเปลี่ยนวลีทริกเกอร์

**Q: รองรับ Linux ไหม?**
A: Wrapper script ใช้ได้บนระบบ Unix ใดก็ได้ `install.sh` ใช้ macOS `launchd` สำหรับเริ่มอัตโนมัติ บน Linux ต้องตั้งค่าบริการ `systemd` เองหรือแก้ไขสคริปต์ติดตั้ง

**Q: Reset ใช้เวลานานเท่าไหร่?**
A: Flag monitor ตรวจทุก 2 วินาที บวกอีก 3 วินาทีรอเริ่มใหม่ รวมประมาณ 5 วินาทีจากส่งคำสั่งถึงเซสชันใหม่พร้อมใช้

## ใบอนุญาต

[MIT](LICENSE)
