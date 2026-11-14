/*
 * firmware_switch.h - 3-in-1 Multi-Boot Engine for LilyGO T-Embed CC1101 Plus
 * Integrates Flipper Zero ESP32 Port (Sor3nt) with Bruce Firmware & Zhilly AI
 */

#ifndef FIRMWARE_SWITCH_H
#define FIRMWARE_SWITCH_H

#include <stdbool.h>
#include <stdint.h>
#include <esp_err.h>

#ifdef __cplusplus
extern "C" {
#endif

// Firmware Targets
typedef enum {
    TARGET_FIRMWARE_FLIPPER = 0,
    TARGET_FIRMWARE_BRUCE,
    TARGET_FIRMWARE_ZHILLY,
} TargetFirmware;

// File paths on SD Card
#define PATH_FIRMWARE_BRUCE   "/sdcard/firmware/bruce.bin"
#define PATH_FIRMWARE_ZHILLY  "/sdcard/firmware/zhilly.bin"
#define PATH_FIRMWARE_BACKUP  "/sdcard/firmware/flipper.bin"

/**
 * @brief Initialize the multi-boot subsystem and check bootloader state.
 * Verifies if the current boot is a cold boot (power switch turned ON)
 * or a soft reboot. If cold boot, ensures boot pointer is Flipper Zero.
 */
void firmware_switch_init(void);

/**
 * @brief Check if a target firmware binary exists on the SD card.
 * @param target TARGET_FIRMWARE_BRUCE or TARGET_FIRMWARE_ZHILLY
 * @return true if binary file is present and readable on SD card.
 */
bool firmware_switch_is_available(TargetFirmware target);

/**
 * @brief Switch and boot into the target firmware from SD card.
 * Reads the .bin file from SD card, writes to OTA slot with progress display,
 * marks boot state as provisional (pending verify), and reboots.
 * 
 * @param target TARGET_FIRMWARE_BRUCE or TARGET_FIRMWARE_ZHILLY
 * @return ESP_OK on success (triggers reboot), or error code on failure.
 */
esp_err_t firmware_switch_to(TargetFirmware target);

/**
 * @brief Configure power-on default boot behavior.
 * When enabled (default: true), turning the physical power switch OFF and ON
 * always forces the device to boot into Flipper Zero.
 */
void firmware_switch_set_revert_on_poweroff(bool revert);
bool firmware_switch_get_revert_on_poweroff(void);

#ifdef __cplusplus
}
#endif

#endif // FIRMWARE_SWITCH_H

