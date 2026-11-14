# LilyGO T-Embed CC1101 Plus — MultiBoot System v2.0.5
### Dual-Boot Firmwares: Flipper Zero ESP32 Port + Bruce RF + Zhilly AI

Welcome Abdullah! Everything is completely aligned with your directives for **v2.0.5**.

---

## ⚡ 3 Dual-Boot Options Available

1. **Option 1: Bruce with Flipper (Dual-Boot) v2.0.5** (`manifest_flipper_bruce.json` / `FLASH_FLIPPER_BRUCE.bat`)
   - **Primary OS on Boot**: **Flipper Zero ESP32 Port** (`ota_0`, `0x020000`)
   - **Secondary OS**: **Bruce RF Firmware** (`ota_1`, `0x4E0000`)
   - **Switching**: Open Flipper Zero Main Menu (press Center OK knob) -> Click **"Switch to Bruce"** (between NFC & Infrared).

2. **Option 2: Bruce with Zhilly AI (Dual-Boot) v2.0.5** (`manifest_dualboot.json` / `FLASH_BRUCE_ZHILLY.bat`)
   - **Primary OS on Boot**: **Bruce RF Firmware** (`ota_0`, `0x020000`)
   - **Secondary OS**: **Zhilly AI v2.0.5** (`ota_2`, `0x880000`)
   - **Switching**: In Bruce -> Reboot -> Switch OTA.

3. **Option 3: Flipper Zero with Zhilly AI (Dual-Boot) v2.0.5** (`manifest_flipper_ai.json` / `FLASH_FLIPPER_ZHILLY.bat`)
   - **Primary OS on Boot**: **Flipper Zero ESP32 Port** (`ota_0`, `0x020000`)
   - **Secondary OS**: **Zhilly AI v2.0.5** (`ota_2`, `0x880000`)
   - **Switching**: Open Flipper Zero Main Menu (press Center OK knob) -> Click **"Switch to Zhilly AI"** (between NFC & Infrared, with animated glitch-tear eyes).

---

## 🎮 How Hardware Switching Works

- **In Flipper Zero**: Press the **Center OK knob** from the desktop to open the Main Menu. Right between **NFC** and **Infrared**, you will find:
  - **"Switch to Zhilly AI"** (animated looping icon: smooth eyes -> glitch with tears -> wipe/blink -> loop)
  - **"Switch to Bruce"** (RF antenna icon)
  Clicking either boots immediately into the target firmware!
- **In Bruce**: Go to **Reboot -> Switch OTA**.
- **In Zhilly AI**: Press the side button or click encoder wheel to switch back immediately.

---

## 🌐 Flashing Instructions

- **Web Serial Flasher**: Run `START_WEB_FLASHER.bat` to launch the local cache-free server at `http://localhost:8000`. Step 2 has all 3 options visible and verified.
- **Direct Terminal Flashing**: Run `FLASH_FLIPPER_BRUCE.bat`, `FLASH_BRUCE_ZHILLY.bat`, or `FLASH_FLIPPER_ZHILLY.bat`.
