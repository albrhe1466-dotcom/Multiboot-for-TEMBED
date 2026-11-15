# ⚡ LilyGO T-Embed CC1101 Plus MultiBoot Suite (v1.1.1.4)

[![Web Flasher](https://img.shields.io/badge/Web%20Flasher-Online%20(Chrome%2FEdge)-brightgreen?style=for-the-badge&logo=googlechrome)](https://albrhe1466-dotcom.github.io/Multiboot-for-TEMBED/)
[![Discord](https://img.shields.io/badge/Discord-Join%20Community-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/JEDH9fNPz)
[![Platform](https://img.shields.io/badge/Hardware-LilyGO%20T--Embed%20CC1101%20Plus-orange?style=for-the-badge)](https://albrhe1466-dotcom.github.io/Multiboot-for-TEMBED/)
[![Version](https://img.shields.io/badge/Version-v1.1.1.4-blue?style=for-the-badge)](https://github.com/albrhe1466-dotcom/Multiboot-for-TEMBED)

An all-in-one MultiBoot firmware suite and interactive Web Serial Flasher designed specifically for the **LilyGO T-Embed CC1101 Plus (ESP32-S3)**. Run dual-boot setups combining **Flipper Zero ESP32**, **Bruce RF**, and **Zhilly Voice AI** with zero-glitch switching, standalone FAT32 SD card packs, and clean hardware control.

---

## 🌐 Instant Web Flasher
👉 **Flash your device now directly in your browser:**  
**https://albrhe1466-dotcom.github.io/Multiboot-for-TEMBED/**  
*(Open in Google Chrome or Microsoft Edge with USB-C connected)*

💬 **Join our Discord Community:**  
**https://discord.gg/JEDH9fNPz**

---

## 🚀 Dual-Boot Configurations

1. **Option 1: Flipper Zero + Bruce** (Dual-boot: Switch right inside the Flipper main menu between NFC & IR, or directly from Bruce).
2. **Option 2: Bruce + Zhilly AI** (Dual-boot RF tools + dedicated single-language AI voice assistant).
3. **Option 3: Flipper Zero + Zhilly AI** (Dual-boot Flipper apps & CC1101 tools + Zhilly AI voice assistant).

---

## 🛠️ Highlights in v1.1.1.4

- **Bruce SD Card Bootloop & Display Hardware Fixes:**
  - Resolved the GPIO `40` hardware conflict on LilyGO T-Embed CC1101 Plus (`TFT_RST` set to `-1` software reset so it no longer collides with speaker `WCLK` on GPIO `40`).
  - Removed the `fillScreen(TFT_RED)` debug pre-fill in `ST7789_Init.h` that caused half-red screen flicker during initialization, and fixed swapped `SCK`/`MISO` constants in `pins_arduino.h`.
  - Lowered shared ST7789 SPI bus frequency to 40 MHz alongside an 80-clock SD wake/retry guard in `setupSdCard()` (`1 MHz` fallback + 8-file FATFS handle minimum) so SD cards stay clean across soft reboots between Bruce, Flipper, and Zhilly.
  - Closed leaked file handles and hardened JSON/pin validation in `config.cpp`, `configPins.cpp` (`sys_i2c` `.to<JsonObject>()` and `W5500_bus` fix), and `theme.cpp` (no blocking red stripe at boot), plus added automatic RTC Safe Boot recovery in `main.cpp` if corrupted SD settings cause consecutive crashes.
  - Synced generated SD Card `bruce.conf` defaults (`colorInverted: 1`, `rfModule: 1`, clean theme/startup keys).

## 🛠️ Highlights from v1.1.1.3

- **Zero Gray-Screen & Bootloop Elimination:**
  - Resolved early LwIP / netif initialization conflicts (`tcpip_mbox: Invalid mbox`) at 1427ms.
  - Fixed 32-byte MMAP asset table filename alignment in `esp_mmap_assets` and `expression_assets.bin` — all 20 eye animations, custom GitLab fonts, and battery icons load without truncation.
  - Black GRAM pre-clearing on ST7789 before backlight enable for clean, flicker-free startups.

- **Dedicated Single-Language AI Builds:**
  - Independent firmware binaries for **English (en-US)**, **Arabic (ar-SA)**, and **Turkish (tr-TR)** with zero Chinese fallback or accidental switching.
  - Full RTL connected Arabic typography and native Turkish glyph support.

- **Global 60-Country GMT & Local Time Sync:**
  - Country-level local time selection (no city confusion) with automatic POSIX timezone configuration written straight to SD and NVS.
  - Clean digital clock display on standby (`--:--` fallback until NTP/RTC sync).

- **Hardware Switching Controls:**
  - **In Flipper Zero:** Press Center OK knob ➔ Select *"Switch to Zhilly AI"* or *"Switch to Bruce"*.
  - **In Bruce:** One-click firmware select from the main menu.
  - **In Zhilly AI:** Rotate rotary encoder **Left** to open Zhilly Options (Brightness, Firmware Switch, Factory Reset), and press the **Side Button** to return.

- **Automated Web Flasher Wizard:**
  - Browser-based Web Serial flasher with automatic transition to Step 4 (Companion Tools & customized FAT32 SD Card Pack generator) once flashing finishes.

---

## 👑 Credits & Special Thanks

- 🤖 **Zhilly Voice AI:** Developed by **siberbaba (sacriphanius)** ([GitLab](https://gitlab.com/sacriphanius/Zhilly) / [GitHub](https://github.com/siberbaba))
- 🦈 **Bruce Firmware:** Developed by **BruceDevices** ([GitHub](https://github.com/brucedevices/firmware))
- 🐬 **Flipper Zero ESP32 Port:** Flipper Community
