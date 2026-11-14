# 64GB MicroSD Card Preparation Guide (FAT32)
Device: LilyGO T-Embed CC1101 Plus

### Why FAT32 is Required:
Although your MicroSD card is 64 GB, ESP32 microcontrollers and the Flipper Zero / Bruce / Zhilly firmware expect **FAT32** file systems. Windows 11/10 default right-click format only allows **exFAT** or **NTFS** for cards larger than 32 GB.

---

### Step-by-Step Formatting Instructions:

#### Option 1: Using Rufus (Recommended & Easiest)
1. Download **Rufus** (Free, portable, from [rufus.ie](https://rufus.ie/)).
2. Insert your 64GB MicroSD card into your computer.
3. Open Rufus:
   - **Device**: Select your 64GB SD card (be very careful not to select your hard drive!).
   - **Boot selection**: Choose `Non bootable`.
   - **Partition scheme**: `MBR`.
   - **File system**: Choose `Large FAT32` (or `FAT32`).
   - **Cluster size**: `32 kilobytes` (Default).
4. Click **START**. In 5 seconds, your 64GB SD card is perfectly formatted in FAT32!

#### Option 2: Using GUIFormat (FAT32 Format tool)
1. Download `guiformat.exe` (FAT32 Format).
2. Select your SD Card drive letter.
3. Set Allocation unit size to `32768`.
4. Click **Start**.

---

### Copying the Files:
Once formatted, simply copy everything inside the `SD_CARD/` folder from this directory directly to the ROOT of your SD card:

```
[SD Card Root]
│
├── firmware/
│   ├── bruce.bin          <-- (Your Bruce firmware binary)
│   └── zhilly.bin         <-- (Your Zhilly AI firmware binary)
├── bruce/
│   └── bruce.conf
├── zhilly/
│   └── config.json
├── badusb/
├── subghz/
├── nfc/
└── apps/
```

