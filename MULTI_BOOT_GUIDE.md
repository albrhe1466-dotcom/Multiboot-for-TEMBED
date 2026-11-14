# 3-in-1 Multi-Boot System Guide for LilyGO T-Embed CC1101 Plus
**Author:** Team Gemini & Abdullah Ibrahim  
**Target Hardware:** LilyGO T-Embed CC1101 Plus (ESP32-S3, 16MB Flash, 8MB PSRAM, Rotary Encoder, ST7789 LCD)

---

## 🌟 1. System Overview

This project unifies three elite cybersecurity & hardware toolkits onto a single LilyGO T-Embed CC1101 Plus:

| Firmware | Role & Storage | Key Features |
| :--- | :--- | :--- |
| **1. Flipper Zero ESP32 Port** | **Main / Permanent OS** (`ota_0` Internal Flash) | Sub-GHz CC1101, BadUSB, NFC, Infrared, Dolphin animations, Desktop Quick Menu |
| **2. Bruce Firmware** | **Secondary Tool** (`/sdcard/firmware/bruce.bin`) | Wardriving, Wi-Fi / BLE deauth & beacons, RF Jammer/Analyzer, JS scripting |
| **3. ZHILLY AI** | **AI Pentest Assistant** (`/sdcard/firmware/zhilly.bin`) | Voice-activated RF replay, dynamic BadUSB injection, Xiaozhi AI core, Animated Eyes |

---

## 🎮 2. How the User Interface Works (Rotary Encoder)

You navigate effortlessly using the physical rotary encoder:

```
[Main Desktop (Flipper)]
         │
         ├── Rotate Wheel LEFT (Counter-Clockwise)
         │       │
         │       ▼
         │   [Quick Access / Control Menu]
         │   ├── Lock Device
         │   ├── Mute / Silent
         │   ├── Bluetooth (BLE)
         │   ├── Wi-Fi (WebUI)
         │   ├── USB-Storage (Mount SD to PC)
         │   ├── Enable qFlipper
         │   │
         │   │  (Scroll down to the bottom)
         │   ▼
         │   ├── 🚀 Switch to Bruce
         │   └── 🤖 Switch to ZHILLY AI
         │
         └── Or via: Applications ➔ Tools ➔ Firmware Switcher
```

---

## ⚡ 3. The Power-Off Behavior (Cold Boot Revert)

> **Abdullah's Requirement:**  
> *"If we turn it off on Bruce firmware, when we open it we will see that we are back on Flipper, not on the same page. How are we going to change it? The Flipper is the only thing that we can change."*

### How This Is Implemented:
1. **Microcontroller Execution Reality:**  
   The ESP32-S3 executes code from its internal SPI flash. Unlike a computer running multiple apps in windows, a microcontroller runs one active firmware at a time. Switching between firmwares performs a fast soft-restart (~2-3 seconds).
2. **Provisional Boot & Cold Boot Reset:**  
   - When Flipper Zero triggers the switch to Bruce or Zhilly, it sets the OTA boot target to `ota_1` in **provisional mode** (`ESP_OTA_IMG_PENDING_VERIFY`).
   - Bruce and Zhilly do not confirm the OTA validation state.
   - When you switch the physical power switch **OFF** and then **ON** (Cold Boot / `ESP_RST_POWERON`), the system detects a power cycle and **automatically resets the boot partition back to `ota_0` (Flipper Zero)**!
   - This guarantees that no matter where you were, turning off the device always brings you back home to **Flipper Zero** upon turning it back on!

---

## 💾 4. MicroSD Card Setup (64 GB)

Your 64 GB MicroSD card must be formatted to **FAT32** (ESP32 cannot read exFAT or NTFS).

### Step 1: Format to FAT32
- Use **Rufus** (portable from [rufus.ie](https://rufus.ie)):
  - Device: Your 64GB SD card
  - Boot selection: `Non bootable`
  - Partition scheme: `MBR`
  - File system: `Large FAT32` (or `FAT32`)
  - Cluster size: `32 kilobytes`
  - Click **START**.

### Step 2: Copy Files to SD Card
Copy the contents of the `SD_CARD/` folder to your SD card root:

```
[MicroSD Card Root]
│
├── firmware/
│   ├── bruce.bin         <-- Bruce Firmware binary
│   └── zhilly.bin        <-- Zhilly AI binary
│
├── bruce/
│   ├── bruce.conf        <-- Bruce configuration
│   └── scripts/          <-- Bruce JavaScript / BadUSB scripts
│
├── zhilly/
│   └── config.json       <-- Zhilly AI config & settings
│
├── subghz/               <-- Flipper Zero Sub-GHz captures
├── badusb/               <-- Flipper Zero BadUSB scripts
├── nfc/                  <-- Flipper Zero NFC files
└── apps/                 <-- Flipper external apps (.fap)
```

---

## 🔗 5. Firmware Binary Download Links

Make sure to download the specific build for **LilyGO T-Embed CC1101 Plus**:

1. **Flipper Zero ESP32 Port (Already flashed and running on your device):**
   - Repository: [Sor3nt/Flipper-Zero-ESP32-Port](https://github.com/Sor3nt/Flipper-Zero-ESP32-Port)

2. **Bruce Firmware:**
   - Web Flasher / Downloads: [bruce.computer/flasher](https://bruce.computer/flasher)
   - GitHub Releases: [BruceDevices/firmware/releases](https://github.com/BruceDevices/firmware/releases)
   - Target File: `Bruce-LilyGo-TEmbed-CC1101.bin` (or launcher compatible `.bin`)
   - Rename to: `bruce.bin` and copy to `/firmware/` on the SD card.

3. **Zhilly AI Firmware:**
   - GitHub: [sacriphanius/Zhilly](https://github.com/sacriphanius/Zhilly) / [topics/zhilly-firmware](https://github.com/topics/zhilly-firmware)
   - GitLab: [sacriphanius/Zhilly](https://gitlab.com/sacriphanius/Zhilly)
   - Target File: `zhilly_t_embed.bin`
   - Rename to: `zhilly.bin` and copy to `/firmware/` on the SD card.

---

## 🛠️ 6. Partition Schemes Available

In the `firmware_switcher/` folder, two partition tables are provided:

1. **`partitions_sd_ota_16mb.csv` (Recommended):**
   - `ota_0` (6.08 MB): Flipper Zero (Permanent)
   - `ota_1` (6.08 MB): Dynamic Slot (Flashes Bruce or Zhilly from SD card when requested)
   - Keeps your 16MB flash clean, safe, and easily upgradable!

2. **`partitions_triple_resident_16mb.csv`:**
   - `ota_0` (4.6 MB): Flipper Zero
   - `ota_1` (4.6 MB): Bruce Firmware
   - `ota_2` (4.6 MB): Zhilly AI
   - Pre-flashes all three into the 16MB flash simultaneously for instantaneous (<0.5s) switching!

