/*
 * desktop_menu_integration.c - Desktop Quick Access Menu Integration
 * Adds "Switch to Bruce" and "Switch to ZHILLY AI" to the Left-Scroll Desktop Menu
 *
 * In Sor3nt's Flipper-Zero-ESP32-Port:
 * Turning the rotary encoder LEFT from the desktop opens the Quick Access / Control Menu.
 * This file demonstrates the additions made to the desktop view and event handlers.
 */

#include <furi.h>
#include <furi_hal.h>
#include <gui/gui.h>
#include <gui/view.h>
#include <gui/canvas.h>
#include <gui/elements.h>
#include "firmware_switch.h"

// Menu item identifiers
typedef enum {
    DesktopMenuLock = 0,
    DesktopMenuMute,
    DesktopMenuBluetooth,
    DesktopMenuWiFi,
    DesktopMenuUsbStorage,
    DesktopMenuQFlipper,
    DesktopMenuSwitchBruce,     // Added: Switch to Bruce Firmware
    DesktopMenuSwitchZhilly,    // Added: Switch to ZHILLY AI
    DesktopMenuItemCount,
} DesktopMenuItemId;

// Text labels for menu items
static const char* desktop_menu_labels[] = {
    [DesktopMenuLock]         = "Lock Device",
    [DesktopMenuMute]         = "Mute / Silent",
    [DesktopMenuBluetooth]    = "Bluetooth (BLE)",
    [DesktopMenuWiFi]         = "Wi-Fi (WebUI)",
    [DesktopMenuUsbStorage]   = "USB-Storage (SD)",
    [DesktopMenuQFlipper]     = "Enable qFlipper",
    [DesktopMenuSwitchBruce]  = "Switch to Bruce",
    [DesktopMenuSwitchZhilly] = "Switch to ZHILLY AI",
};

/**
 * @brief Handles selection of menu items in the Desktop Left Menu
 */
void desktop_menu_callback_select(DesktopMenuItemId index) {
    switch (index) {
        case DesktopMenuSwitchBruce: {
            FURI_LOG_I("DESKTOP", "User selected: Switch to Bruce");
            if (!firmware_switch_is_available(TARGET_FIRMWARE_BRUCE)) {
                // Show user notification that bruce.bin is missing on SD card
                FURI_LOG_E("DESKTOP", "bruce.bin missing in /sdcard/firmware/!");
                // Notice popup: "Insert SD card with /firmware/bruce.bin"
                return;
            }
            // Trigger switch to Bruce
            firmware_switch_to(TARGET_FIRMWARE_BRUCE);
            break;
        }

        case DesktopMenuSwitchZhilly: {
            FURI_LOG_I("DESKTOP", "User selected: Switch to ZHILLY AI");
            if (!firmware_switch_is_available(TARGET_FIRMWARE_ZHILLY)) {
                // Show user notification that zhilly.bin is missing on SD card
                FURI_LOG_E("DESKTOP", "zhilly.bin missing in /sdcard/firmware/!");
                return;
            }
            // Trigger switch to Zhilly AI
            firmware_switch_to(TARGET_FIRMWARE_ZHILLY);
            break;
        }

        default:
            // Existing handlers for Bluetooth, WiFi, USB-Storage, etc.
            break;
    }
}

