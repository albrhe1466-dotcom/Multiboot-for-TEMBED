/*
 * firmware_switch.c - 3-in-1 Multi-Boot Engine Implementation
 * Supports LilyGO T-Embed CC1101 Plus (ESP32-S3, 16MB Flash)
 *
 * Partition Layout:
 * - ota_0 (0x020000, seq=1): Bruce Firmware (T-Embed CC1101 Plus)
 * - ota_1 (0x4E0000, seq=2): Flipper Zero ESP32 Port (by Sor3nt)
 * - ota_2 (0x880000, seq=3): Zhilly AI (by siberbaba / sacriphanius)
 */

#include "firmware_switch.h"
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include <esp_system.h>
#include <esp_log.h>
#include <esp_ota_ops.h>
#include <esp_partition.h>
#include <esp_rom_crc.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>

static const char *TAG = "MULTI_BOOT";

typedef struct {
    uint8_t slot_idx; /* 0 = Bruce (ota_0), 1 = Flipper (ota_1), 2 = Zhilly (ota_2) */
} SwitchTaskArgs;

/*
 * MUST run on an internal DRAM stack (spawned via xTaskCreate) because
 * esp_partition_erase_range / esp_partition_write / esp_restart disable
 * SPI flash/PSRAM cache and will crash if called from a PSRAM FuriThread stack.
 */
static void switch_ota_slot_dram_task(void *pvParameters) {
    SwitchTaskArgs *args = (SwitchTaskArgs *)pvParameters;
    uint8_t slot_idx = args->slot_idx;

    const esp_partition_t *otadata_part = esp_partition_find_first(
        ESP_PARTITION_TYPE_DATA, ESP_PARTITION_SUBTYPE_DATA_OTA, NULL);

    if (otadata_part != NULL) {
        esp_ota_select_entry_t new_entry;
        memset(&new_entry, 0xFF, sizeof(new_entry));
        /* Bootloader index = (ota_seq - 1) % 3 -> 1=ota_0, 2=ota_1, 3=ota_2 */
        new_entry.ota_seq = (uint32_t)(slot_idx + 1);
        new_entry.ota_state = ESP_OTA_IMG_VALID;
        new_entry.crc = esp_rom_crc32_le(UINT32_MAX, (const uint8_t *)&new_entry.ota_seq, 4);

        esp_partition_erase_range(otadata_part, 0, otadata_part->size);
        esp_partition_write(otadata_part, 0, &new_entry, sizeof(new_entry));
        esp_partition_write(otadata_part, 4096, &new_entry, sizeof(new_entry));
    }

    vTaskDelay(pdMS_TO_TICKS(150));
    esp_restart();
    vTaskDelete(NULL);
}

void firmware_switch_init(void) {
    ESP_LOGI(TAG, "Initializing 3-in-1 Multi-Boot Engine (Bruce / Flipper / Zhilly AI)");
    esp_ota_mark_app_valid_cancel_rollback();
}

bool firmware_switch_is_available(TargetFirmware target) {
    (void)target;
    return true;
}

esp_err_t firmware_switch_to(TargetFirmware target) {
    static SwitchTaskArgs s_args;
    switch (target) {
        case TARGET_FIRMWARE_BRUCE:
            s_args.slot_idx = 0; /* ota_0 */
            break;
        case TARGET_FIRMWARE_FLIPPER:
            s_args.slot_idx = 1; /* ota_1 */
            break;
        case TARGET_FIRMWARE_ZHILLY:
            s_args.slot_idx = 2; /* ota_2 */
            break;
        default:
            return ESP_ERR_INVALID_ARG;
    }

    xTaskCreate(switch_ota_slot_dram_task, "ota_sw", 4096, &s_args, 10, NULL);
    return ESP_OK;
}
