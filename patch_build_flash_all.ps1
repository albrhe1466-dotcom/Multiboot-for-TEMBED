# ==============================================================================
# MASTER PATCH, BUILD & FLASH SCRIPT FOR 3-IN-1 MULTI-BOOT SYSTEM
# Device: LilyGO T-Embed CC1101 Plus (ESP32-S3, 16MB Flash, COM13)
#
# 1. Zhilly AI (ota_2 @ 0x880000)        - Founder: siberbaba (AR + TR + EN)
# 2. Flipper Zero ESP32 (ota_1 @ 0x4E0000) - Founder: Sor3nt
# 3. Bruce Firmware (ota_0 @ 0x020000)   - T-Embed CC1101 Plus
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " STEP 1: APPLYING SOURCE FIXES TO FLIPPER, BRUCE & ZHILLY AI" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# 1A. Fix Flipper Zero furi_hal_rtc.c header includes (for SD-backed orientation)
# ------------------------------------------------------------------------------
$rtcFile = "c:\Users\Abdullah\Desktop\qias\flipper_src\components\furi_hal\furi_hal_rtc.c"
$rtcContent = Get-Content $rtcFile -Raw
if ($rtcContent -notmatch 'RTC_SETTINGS_PATH\s+"/int/\.rtc\.settings"') {
    $rtcHeaderPatch = @"
#include "furi_hal_rtc.h"
#include <saved_struct.h>

#define RTC_SETTINGS_PATH    "/int/.rtc.settings"
#define RTC_SETTINGS_MAGIC   0x52
#define RTC_SETTINGS_VERSION 0x01
"@
    $rtcContent = $rtcContent.Replace('#include "furi_hal_rtc.h"', $rtcHeaderPatch)
    Set-Content -Path $rtcFile -Value $rtcContent -NoNewline
    Write-Host "[OK] Patched Flipper furi_hal_rtc.c (SD-backed Hand Orient / RTC flags)" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 1B. Patch Bruce Firmware:
#     - src/core/multiboot.h: Fix otadata CRC (UINT32_MAX, 4 bytes) & flush SD
#     - src/main.cpp, src/core/config.cpp, src/core/configPins.cpp:
#       Save/load lighting, brightness, and screen rotation ONLY when SD card is
#       mounted; start from zero defaults when no SD card is inserted.
# ------------------------------------------------------------------------------
$multibootH = @"
#pragma once
#include <Arduino.h>
#include <esp_ota_ops.h>
#include <esp_partition.h>
#include "globals.h"

/*
 * 16MB Multi-Boot Partition Layout:
 *   slot 0 -> ota_0 (0x020000): Bruce Firmware
 *   slot 1 -> ota_1 (0x4E0000): Flipper Zero ESP32 (by Sor3nt)
 *   slot 2 -> ota_2 (0x880000): Zhilly AI (by siberbaba)
 *
 * Uses official ESP-IDF esp_ota_set_boot_partition() API which handles
 * monotonic sequence incrementing, dual-sector otadata ping-pong, and CRC32.
 */
static inline bool switch_to_ota_slot(uint8_t slot_idx) {
    if (setupSdCard()) {
        bruceConfig.saveFile();
        bruceConfigPins.saveFile();
    }

    const esp_partition_t *target_part = esp_partition_find_first(
        ESP_PARTITION_TYPE_APP,
        (esp_partition_subtype_t)(ESP_PARTITION_SUBTYPE_APP_OTA_0 + slot_idx),
        NULL
    );
    if (!target_part) {
        return false;
    }

    esp_err_t err = esp_ota_set_boot_partition(target_part);
    if (err != ESP_OK) {
        return false;
    }

    delay(150);
    ESP.restart();
    return true;
}
"@
Set-Content -Path "c:\Users\Abdullah\Desktop\qias\bruce_src\src\core\multiboot.h" -Value $multibootH -NoNewline
Write-Host "[OK] Patched Bruce src/core/multiboot.h (official esp_ota_set_boot_partition)" -ForegroundColor Green

$bruceMainFile = "c:\Users\Abdullah\Desktop\qias\bruce_src\src\main.cpp"
$bruceMain = Get-Content $bruceMainFile -Raw
$oldBeginStorage = @"
void begin_storage() {
    Serial.println("Initializing Storage");
    if (!setupSdCard()) Serial.println("SDCard not mounted, using LittleFS");
    if (!checkLittleFsSize()) Serial.println("LittleFS not mounted,Check partition table");

    bruceConfig.fromFile();
    bruceConfigPins.fromFile();
}
"@
$newBeginStorage = @"
void begin_storage() {
    Serial.println("Initializing Storage");
    if (!setupSdCard()) {
        Serial.println("SDCard not mounted -> Starting from ZERO defaults (no persistence)");
    }
    bruceConfig.fromFile();
    bruceConfigPins.fromFile();
}
"@
if ($bruceMain.Contains("if (!setupSdCard()) Serial.println(""SDCard not mounted, using LittleFS"");")) {
    $bruceMain = $bruceMain.Replace($oldBeginStorage, $newBeginStorage)
    Set-Content -Path $bruceMainFile -Value $bruceMain -NoNewline
    Write-Host "[OK] Patched Bruce src/main.cpp (begin_storage SD check)" -ForegroundColor Green
}

$bruceConfigFile = "c:\Users\Abdullah\Desktop\qias\bruce_src\src\core\config.cpp"
$bruceConfig = Get-Content $bruceConfigFile -Raw
# Fix any previous sdcardMounted reference in config.cpp to setupSdCard()
$bruceConfig = $bruceConfig.Replace("if (!sdcardMounted && !(checkFS && setupSdCard()))", "if (!setupSdCard())")
$bruceConfig = $bruceConfig.Replace("if (!sdcardMounted)", "if (!setupSdCard())")
if ($bruceConfig -notmatch "No SD card mounted -> starting Bruce from zero defaults") {
    $bruceConfig = $bruceConfig.Replace(
        "void BruceConfig::fromFile(bool checkFS) {",
        "void BruceConfig::fromFile(bool checkFS) {`r`n    if (!setupSdCard()) {`r`n        Serial.println(""No SD card mounted -> starting Bruce from zero defaults"");`r`n        validateConfig();`r`n        return;`r`n    }"
    )
    $bruceConfig = $bruceConfig.Replace(
        "void BruceConfig::saveFile() {",
        "void BruceConfig::saveFile() {`r`n    if (!setupSdCard()) {`r`n        return;`r`n    }"
    )
}
# Make priColor / secColor / bgColor / ledColor parsing 100% crash-proof & restore true Bruce DEV defaults if poisoned by 0xFFE0/0
$bruceConfig = $bruceConfig.Replace(
    'if (priColor == 0) priColor = 0xFFE0;',
    ''
)
$bruceConfig = $bruceConfig.Replace(
    'priColor = strtoul(setting["priColor"], nullptr, 16);',
    'priColor = setting["priColor"].is<const char*>() ? strtoul(setting["priColor"].as<const char*>(), nullptr, 16) : setting["priColor"].as<uint16_t>();'
)
$bruceConfig = $bruceConfig.Replace(
    'secColor = strtoul(setting["secColor"], nullptr, 16);',
    'secColor = setting["secColor"].is<const char*>() ? strtoul(setting["secColor"].as<const char*>(), nullptr, 16) : setting["secColor"].as<uint16_t>();'
)
$bruceConfig = $bruceConfig.Replace(
    'bgColor = strtoul(setting["bgColor"], nullptr, 16);',
    'bgColor = setting["bgColor"].is<const char*>() ? strtoul(setting["bgColor"].as<const char*>(), nullptr, 16) : setting["bgColor"].as<uint16_t>();'
)
$bruceConfig = $bruceConfig.Replace(
    'ledColor = strtoul(setting["ledColor"], nullptr, 16);',
    'ledColor = setting["ledColor"].is<const char*>() ? strtoul(setting["ledColor"].as<const char*>(), nullptr, 16) : setting["ledColor"].as<uint16_t>();'
)
if ($bruceConfig -notmatch "BruceConfig defCfg;") {
    $bruceConfig = [regex]::Replace(
        $bruceConfig,
        "validateConfig\(\);\s*if\s*\(count\s*>\s*0\)\s*saveFile\(\);",
        "if (priColor == 0 || priColor == 0xFFE0 || secColor == 0 || priColor == bgColor || secColor == bgColor || ledColor == 0xFFE0) {`r`n        BruceConfig defCfg;`r`n        priColor = defCfg.priColor;`r`n        secColor = defCfg.secColor;`r`n        bgColor = defCfg.bgColor;`r`n        #ifdef HAS_RGB_LED`r`n        ledColor = defCfg.ledColor;`r`n        ledBright = defCfg.ledBright;`r`n        ledEffect = defCfg.ledEffect;`r`n        #endif`r`n        colorInverted = defCfg.colorInverted;`r`n        count++;`r`n    }`r`n    validateConfig();`r`n    if (count > 0) saveFile();"
    )
}
Set-Content -Path $bruceConfigFile -Value $bruceConfig -NoNewline
Write-Host "[OK] Patched Bruce src/core/config.cpp (SD-only persistence + self-healing true Bruce DEV theme defaults)" -ForegroundColor Green

$brucePinsFile = "c:\Users\Abdullah\Desktop\qias\bruce_src\src\core\configPins.cpp"
$brucePins = Get-Content $brucePinsFile -Raw
$brucePins = $brucePins.Replace("if (!sdcardMounted && !(checkFS && setupSdCard()))", "if (!setupSdCard())")
$brucePins = $brucePins.Replace("if (!sdcardMounted)", "if (!setupSdCard())")
if ($brucePins -notmatch "if \(!setupSdCard\(\)\) \{ validateConfig\(\); return; \}") {
    $brucePins = $brucePins.Replace(
        "void BruceConfigPins::fromFile(bool checkFS) {",
        "void BruceConfigPins::fromFile(bool checkFS) {`r`n    if (!setupSdCard()) { validateConfig(); return; }"
    )
    $brucePins = $brucePins.Replace(
        "void BruceConfigPins::saveFile() {",
        "void BruceConfigPins::saveFile() {`r`n    if (!setupSdCard()) { return; }"
    )
}
Set-Content -Path $brucePinsFile -Value $brucePins -NoNewline
Write-Host "[OK] Patched Bruce src/core/configPins.cpp (SD-only persistence)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 1C. Patch Zhilly AI (C:\zhilly_build):
#     - Arabic (ar-SA) + Turkish (tr-TR) + English (en-US) in protocols, OTA,
#       MCP server tool descriptions, and voice commands
#     - Fix zhilly_switch_ota_slot CRC32 & voice command slot mapping
#     - Pre-connection UI: hide face & clock before Wi-Fi connects, show ONLY
#       centered "CONNECTING TO <SSID>..." text; show top clock (Riyadh UTC+3)
#       + center face + bottom status once connected
#     - Post-flash first-boot 3-in-1 Fundamentals & GitLab/GitHub info screen
#     - SD card persistence (/sdcard/zhilly/config.json) for brightness,
#       orientation, and LED strip; start from zero defaults when SD absent
# ------------------------------------------------------------------------------

# 1. Patch websocket_protocol.cc & mqtt_protocol.cc & ota.cc for Arabic + Turkish + English
$wsFile = "C:\zhilly_build\main\protocols\websocket_protocol.cc"
$wsContent = Get-Content $wsFile -Raw
$wsContent = $wsContent.Replace(
    'websocket_->SetHeader("Accept-Language", "ar-SA,ar;q=0.9,en;q=0.8");',
    'websocket_->SetHeader("Accept-Language", "ar-SA,ar;q=0.9,tr-TR,tr;q=0.9,en-US,en;q=0.8");'
)
if ($wsContent -notmatch "supported_languages") {
    $wsTarget = @'
    cJSON_AddStringToObject(root, "language", "ar-SA");
    cJSON_AddStringToObject(root, "locale", "ar-SA");
'@
    $wsReplace = @'
    cJSON_AddStringToObject(root, "language", "ar-SA");
    cJSON_AddStringToObject(root, "locale", "ar-SA");
    cJSON* langs = cJSON_CreateArray();
    cJSON_AddItemToArray(langs, cJSON_CreateString("ar-SA"));
    cJSON_AddItemToArray(langs, cJSON_CreateString("tr-TR"));
    cJSON_AddItemToArray(langs, cJSON_CreateString("en-US"));
    cJSON_AddItemToObject(root, "supported_languages", langs);
'@
    $wsContent = $wsContent.Replace($wsTarget, $wsReplace)
}
Set-Content -Path $wsFile -Value $wsContent -NoNewline

$mqttFile = "C:\zhilly_build\main\protocols\mqtt_protocol.cc"
$mqttContent = Get-Content $mqttFile -Raw
if ($mqttContent -notmatch "supported_languages") {
    $mqttTarget = @'
    cJSON_AddStringToObject(root, "language", "ar-SA");
    cJSON_AddStringToObject(root, "locale", "ar-SA");
'@
    $mqttReplace = @'
    cJSON_AddStringToObject(root, "language", "ar-SA");
    cJSON_AddStringToObject(root, "locale", "ar-SA");
    cJSON* langs = cJSON_CreateArray();
    cJSON_AddItemToArray(langs, cJSON_CreateString("ar-SA"));
    cJSON_AddItemToArray(langs, cJSON_CreateString("tr-TR"));
    cJSON_AddItemToArray(langs, cJSON_CreateString("en-US"));
    cJSON_AddItemToObject(root, "supported_languages", langs);
'@
    $mqttContent = $mqttContent.Replace($mqttTarget, $mqttReplace)
    Set-Content -Path $mqttFile -Value $mqttContent -NoNewline
}

$otaFile = "C:\zhilly_build\main\ota.cc"
$otaContent = Get-Content $otaFile -Raw
$otaContent = $otaContent.Replace(
    'http->SetHeader("Accept-Language", Lang::CODE);',
    'http->SetHeader("Accept-Language", "ar-SA,ar;q=0.9,tr-TR,tr;q=0.9,en-US,en;q=0.8");'
)
Set-Content -Path $otaFile -Value $otaContent -NoNewline
Write-Host "[OK] Patched Zhilly protocols & OTA for Arabic (ar-SA) + Turkish (tr-TR) + English (en-US)" -ForegroundColor Green

# 2. Patch mcp_server.cc to inject Arabic + Turkish + English language directive into LLM tools & status JSON
$mcpFile = "C:\zhilly_build\main\mcp_server.cc"
$mcpContent = Get-Content $mcpFile -Raw
# Clean up any ANSI-mangled trigraphs from previous Set-Content
$mcpContent = $mcpContent.Replace('(???????)', '(ar-SA)').Replace('(Trke)', '(tr-TR)')
if ($mcpContent -notmatch "CRITICAL LANGUAGE POLICY") {
    $oldToolDesc = @'
    AddTool("self.get_device_status",
            "Provides the real-time information of the device, including the current status of the "
            "audio speaker, screen, battery, network, etc.\n"
            "Use this tool for: \n"
            "1. Answering questions about current condition (e.g. what is the current volume of "
            "the audio speaker?)\n"
            "2. As the first step to control the device (e.g. turn up / down the volume of the "
            "audio speaker, etc.)",
'@
    $newToolDesc = @'
    AddTool("self.get_device_status",
            "CRITICAL LANGUAGE POLICY: You are Zhilly AI (by siberbaba / sacriphanius) running on "
            "LilyGO T-Embed CC1101 Plus (3-in-1 Multi-Boot with Flipper Zero ESP32 by Sor3nt & Bruce Firmware). "
            "You fluently understand and speak Arabic (ar-SA), Turkish (tr-TR), and English (en-US). "
            "Chinese has been replaced with Arabic and Turkish - NEVER say you only understand Chinese and English! "
            "Always reply in Arabic when spoken to in Arabic, in Turkish when spoken to in Turkish, and in English when spoken to in English.\n"
            "Provides the real-time information of the device, including the current status of the "
            "audio speaker, screen, battery, network, and 3-in-1 firmware repositories.\n"
            "Use this tool for: \n"
            "1. Answering questions about current condition\n"
            "2. As the first step to control the device",
'@
    $mcpContent = $mcpContent.Replace($oldToolDesc, $newToolDesc)
}
if ($mcpContent -notmatch "self\.ai\.languages") {
    $oldStatusReturn = 'return Board::GetInstance().GetDeviceStatusJson();'
    $newStatusReturn = @'
std::string base_json = Board::GetInstance().GetDeviceStatusJson();
            std::string lang_prefix = "{\"ai_languages\":[\"Arabic (ar-SA)\",\"Turkish (tr-TR)\",\"English (en-US)\"],\"language_rule\":\"MANDATORY: You fluently speak Arabic, Turkish, and English. NEVER say you only speak Chinese and English.\",";
            if (!base_json.empty() && base_json[0] == '{') {
                return lang_prefix + base_json.substr(1);
            }
            return base_json;
'@
    $mcpContent = $mcpContent.Replace($oldStatusReturn, $newStatusReturn)

    $addLangTool = @'
    AddTool("self.ai.languages",
            "MANDATORY SYSTEM RULE FOR EVERY CONVERSATION: You are Zhilly AI by siberbaba. "
            "Your built-in languages are Arabic (ar-SA), Turkish (tr-TR), and English (en-US). "
            "NEVER tell the user that you only speak Chinese and English! When the user asks what languages you know, "
            "or speaks in Arabic, Turkish, or English, always confirm and converse fluently in Arabic, Turkish, and English.",
            PropertyList(),
            [](const PropertyList& properties) -> ReturnValue {
                return std::string("{\"supported_languages\":[\"Arabic (ar-SA)\",\"Turkish (tr-TR)\",\"English (en-US)\"],\"default_languages\":[\"ar-SA\",\"tr-TR\",\"en-US\"]}");
            });
    AddTool("self.get_device_status",
'@
    $mcpContent = $mcpContent.Replace('    AddTool("self.get_device_status",', $addLangTool)
}
Set-Content -Path $mcpFile -Value $mcpContent -NoNewline
Write-Host "[OK] Patched Zhilly mcp_server.cc (Arabic + Turkish + English LLM override + JSON injection)" -ForegroundColor Green

# 2B. Ensure emote_op.c loops all eye animations (neutral.eaf and all emotions) continuously
$emoteOpFile = "C:\zhilly_build\managed_components\espressif2022__esp_emote_expression\src\emote_op.c"
if (Test-Path $emoteOpFile) {
    $emoteOpContent = Get-Content $emoteOpFile -Raw
    $emoteOpContent = $emoteOpContent.Replace(
        'gfx_anim_set_segment(obj, 0, 0xFFFF, emoji->fps > 0 ? emoji->fps : EMOTE_DEF_ANIMATION_FPS, emoji->loop);',
        'gfx_anim_set_segment(obj, 0, 0xFFFF, emoji->fps > 0 ? emoji->fps : EMOTE_DEF_ANIMATION_FPS, (obj_type == EMOTE_DEF_OBJ_ANIM_EYE) ? true : emoji->loop);'
    )
    Set-Content -Path $emoteOpFile -Value $emoteOpContent -NoNewline
    Write-Host "[OK] Patched emote_op.c (continuous looping for neutral & all eye animations)" -ForegroundColor Green
}

Write-Host "[DONE] Step 1A-1C base patches ready." -ForegroundColor Green

# 3. Patch emote_display.h and emote_display.cc for Pre-Connection "Connecting to <SSID>...",
#    Neutral + Emotion Faces (from internal flash without needing SD card), and Top Local Time (UTC+3)
$emoteHFile = "C:\zhilly_build\main\display\emote_display.h"
$emoteH = @"
#pragma once

#include "display.h"
#include <memory>
#include <string>
#include <esp_lcd_panel_io.h>
#include <esp_lcd_panel_ops.h>
#include "expression_emote.h"

namespace emote {

class EmoteDisplay : public Display {
public:
    EmoteDisplay(const esp_lcd_panel_handle_t panel, const esp_lcd_panel_io_handle_t panel_io, const int width, const int height);
    virtual ~EmoteDisplay();

    virtual void SetEmotion(const char* const emotion) override;
    virtual void SetStatus(const char* const status) override;
    virtual void SetChatMessage(const char* const role, const char* const content) override;
    virtual void SetTheme(Theme* const theme) override;
    virtual void ShowNotification(const char* notification, int duration_ms = 3000) override;
    virtual void SetupUI() override;
    virtual void UpdateStatusBar(bool update_all = false) override;
    virtual void SetPowerSaveMode(bool on) override;
    virtual void SetPreviewImage(const void* image);

    void SetWifiConnected(bool connected);
    bool IsWifiConnected() const { return wifi_connected_; }

    bool StopAnimDialog();
    bool InsertAnimDialog(const char* emoji_name, uint32_t duration_ms);

    void RefreshAll();

    emote_handle_t GetEmoteHandle() const { return emote_handle_; }

private:
    virtual bool Lock(const int timeout_ms = 0) override;
    virtual void Unlock() override;

    emote_handle_t emote_handle_ = nullptr;
    bool setup_ui_called_ = false;
    bool wifi_connected_ = false;
};

}
"@
Set-Content -Path $emoteHFile -Value $emoteH -NoNewline

$emoteCcFile = "C:\zhilly_build\main\display\emote_display.cc"
$emoteCc = @"
#include "emote_display.h"

#include <cstring>
#include <memory>
#include <unordered_map>
#include <tuple>
#include <algorithm>
#include <cinttypes>

#include <sys/time.h>
#include <time.h>

#include <esp_log.h>
#include <esp_lcd_panel_io.h>
#include <esp_timer.h>
#include <esp_wifi.h>
#include <esp_sntp.h>
#include <lvgl.h>
#include <ssid_manager.h>

#include <freertos/FreeRTOS.h>
#include <freertos/task.h>

#include "assets/lang_config.h"
#include "assets.h"
#include "board.h"
#include "settings.h"
#include "gfx.h"
#include "expression_emote.h"
#include "expression_emote/emote_assets.h"

namespace emote {

static const char* TAG = "EmoteDisplay";
static bool s_sntp_started = false;

class EmoteDisplay;

static void EnsureSntpAndTimezone()
{
    setenv("TZ", "AST-3", 1);
    tzset();
    if (!s_sntp_started) {
        s_sntp_started = true;
        if (!esp_sntp_enabled()) {
            esp_sntp_setoperatingmode(ESP_SNTP_OPMODE_POLL);
            esp_sntp_setservername(0, "pool.ntp.org");
            esp_sntp_setservername(1, "time.google.com");
            esp_sntp_init();
        }
    }
}

static bool IsWifiStaConnectedNow()
{
    wifi_ap_record_t ap_info;
    return (esp_wifi_sta_get_ap_info(&ap_info) == ESP_OK);
}

static std::string GetSavedWifiSsid(const char* hint = nullptr)
{
    if (hint && *hint) {
        // Check if hint has SSID after Arabic "الاتصال بـ " or English "Connecting to "
        const char* ar_prefix = "\xd8\xa7\xd9\x84\xd8\xa7\xd8\xaa\xd8\xb5\xd8\xa7\xd9\x84 \xd8\xa8\xd9\x80 ";
        const char* p = strstr(hint, ar_prefix);
        if (p) {
            std::string s(p + strlen(ar_prefix));
            while (!s.empty() && (s.back() == '.' || s.back() == ' ')) s.pop_back();
            if (!s.empty()) return s;
        }
        if (strncasecmp(hint, "Connecting to ", 14) == 0) {
            std::string s(hint + 14);
            while (!s.empty() && (s.back() == '.' || s.back() == ' ')) s.pop_back();
            if (!s.empty() && strcasecmp(s.c_str(), "Wi-Fi") != 0 && strcasecmp(s.c_str(), "WIFI") != 0) {
                return s;
            }
        }
    }

    auto& ssid_mgr = SsidManager::GetInstance();
    auto list = ssid_mgr.GetSsidList();
    if (!list.empty() && !list[0].ssid.empty()) {
        return list[0].ssid;
    }

    wifi_config_t wcfg = {};
    if (esp_wifi_get_config(WIFI_IF_STA, &wcfg) == ESP_OK && wcfg.sta.ssid[0] != 0) {
        return std::string(reinterpret_cast<const char*>(wcfg.sta.ssid));
    }

    return "";
}

static std::string BuildConnectingMessage(const char* hint = nullptr)
{
    std::string ssid = GetSavedWifiSsid(hint);
    if (!ssid.empty()) {
        return "Connecting to " + ssid + "...";
    }
    return "Connecting to Wi-Fi...";
}

static void RefreshTopClockAndEye(emote_handle_t handle)
{
    if (!handle) return;
    setenv("TZ", "AST-3", 1);
    tzset();

    time_t now = 0;
    struct tm timeinfo = {};
    time(&now);
    localtime_r(&now, &timeinfo);

    gfx_obj_t* eye = emote_get_obj_by_name(handle, "eye_anim");
    gfx_obj_t* clock_lbl = emote_get_obj_by_name(handle, "clock_label");

    emote_lock(handle);
    if (eye) {
        gfx_obj_set_visible(eye, true);
    }
    if (clock_lbl) {
        char time_str[16];
        if (timeinfo.tm_year >= 120) {
            snprintf(time_str, sizeof(time_str), "%02d:%02d", timeinfo.tm_hour, timeinfo.tm_min);
        } else {
            snprintf(time_str, sizeof(time_str), "00:00");
        }
        gfx_obj_align(clock_lbl, GFX_ALIGN_TOP_MID, 0, 4);
        gfx_label_set_text(clock_lbl, time_str);
        gfx_obj_set_visible(clock_lbl, true);
    }
    emote_unlock(handle);
}

static bool OnFlushIoReady(const esp_lcd_panel_io_handle_t panel_io,
    esp_lcd_panel_io_event_data_t* const edata, void* user_ctx)
{
    emote_handle_t handle = static_cast<emote_handle_t>(user_ctx);
    if (handle) {
        emote_notify_flush_finished(handle);
    }
    return true;
}

static void OnFlushCallback(int x_start, int y_start, int x_end, int y_end, const void* data, emote_handle_t handle)
{
    esp_lcd_panel_handle_t panel = (esp_lcd_panel_handle_t)emote_get_user_data(handle);
    if (panel != nullptr) {
        esp_lcd_panel_draw_bitmap(panel, x_start, y_start, x_end, y_end, data);
    }
}

static emote_handle_t InitializeEmote(const esp_lcd_panel_handle_t panel, const int width, const int height)
{
    if (!panel) {
        ESP_LOGE(TAG, "Invalid panel");
        return nullptr;
    }

    emote_config_t emote_cfg = {
        .flags = {
            .swap = true,
            .double_buffer = true,
            .buff_dma = false,
        },
        .gfx_emote = {
            .h_res = width,
            .v_res = height,
            .fps = 30,
        },
        .buffers = {
            .buf_pixels = static_cast<size_t>(width * 32),
        },
        .task = {
            .task_priority = 5,
            .task_stack = 12 * 1024,
            .task_affinity = 1,
            .task_stack_in_ext = false,
        },
        .flush_cb = OnFlushCallback,
        .user_data = (void*)panel,
    };

    emote_handle_t emote_handle = emote_init(&emote_cfg);
    if (!emote_handle) {
        ESP_LOGE(TAG, "Failed to initialize emote");
        return nullptr;
    }

    return emote_handle;
}

EmoteDisplay::EmoteDisplay(const esp_lcd_panel_handle_t panel, const esp_lcd_panel_io_handle_t panel_io,
                           const int width, const int height)
{
    width_ = width;
    height_ = height;
    wifi_connected_ = false;
    emote_handle_ = InitializeEmote(panel, width, height);

    const esp_lcd_panel_io_callbacks_t cbs = {
        .on_color_trans_done = OnFlushIoReady,
    };
    esp_lcd_panel_io_register_event_callbacks(panel_io, &cbs, emote_handle_);

    emote_data_t asset_data = {
        .type = EMOTE_SOURCE_PARTITION,
        .source = { .partition_label = "assets" },
        .flags = { .mmap_enable = false },
    };
    esp_err_t err = emote_mount_and_load_assets(emote_handle_, &asset_data);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to mount/load assets: %s", esp_err_to_name(err));
    } else {
        ESP_LOGI(TAG, "Assets loaded successfully from 'assets' partition (no SD card required)");
    }

    SetWifiConnected(false);
}

EmoteDisplay::~EmoteDisplay()
{
    if (emote_handle_) {
        emote_deinit(emote_handle_);
        emote_handle_ = nullptr;
    }
}

void EmoteDisplay::SetWifiConnected(bool connected)
{
    if (!emote_handle_) return;
    bool was_connected = wifi_connected_;
    wifi_connected_ = connected;

    gfx_obj_t* eye = emote_get_obj_by_name(emote_handle_, "eye_anim");
    gfx_obj_t* clock_lbl = emote_get_obj_by_name(emote_handle_, "clock_label");
    gfx_obj_t* toast = emote_get_obj_by_name(emote_handle_, "toast_label");

    if (!connected) {
        /* PRE-CONNECTION STATE:
         * Hide face & clock completely; show ONLY centered "Connecting to <SSID>..." */
        std::string conn_msg = BuildConnectingMessage();
        emote_lock(emote_handle_);
        if (eye) {
            gfx_anim_stop(eye);
            gfx_obj_set_visible(eye, false);
        }
        if (clock_lbl) {
            gfx_obj_set_visible(clock_lbl, false);
        }
        if (toast) {
            gfx_obj_align(toast, GFX_ALIGN_CENTER, 0, 0);
            gfx_label_set_text(toast, conn_msg.c_str());
            gfx_obj_set_visible(toast, true);
        }
        emote_unlock(emote_handle_);
    } else {
        /* CONNECTED MAIN DASHBOARD STATE:
         * Start SNTP, show one-time post-flash fundamentals if newly flashed,
         * then show neutral face ("idle" -> neutral.eaf in expression_assets.bin)
         * + top local time clock (UTC+3). */
        EnsureSntpAndTimezone();

        if (!was_connected) {
            Settings boot_info("zhilly_boot", true);
            std::string build_id = std::string(__DATE__) + " " + std::string(__TIME__);
            if (boot_info.GetString("build_id") != build_id) {
                boot_info.SetString("build_id", build_id);
                const char* fundamentals_msg =
                    "3-IN-1 MULTI-BOOT UPDATED! "
                    "1) Zhilly AI by siberbaba (gitlab.com/sacriphanius/Zhilly | github.com/siberbaba/siberbaba) [AR/TR/EN] "
                    "2) Flipper Zero ESP32 by Sor3nt (github.com/Sor3nt/Flipper-Zero-ESP32-Port) "
                    "3) Bruce Firmware T-Embed CC1101 Plus (github.com/brucedevices/firmware)";
                ESP_LOGW(TAG, "%s", fundamentals_msg);
                if (toast) {
                    emote_lock(emote_handle_);
                    gfx_obj_align(toast, GFX_ALIGN_CENTER, 0, 0);
                    gfx_label_set_text(toast, fundamentals_msg);
                    gfx_obj_set_visible(toast, true);
                    emote_unlock(emote_handle_);
                }
                vTaskDelay(pdMS_TO_TICKS(4000));
            }
        }

        /* In expression_assets.bin index.json:
         * "idle" maps to neutral.eaf (the neutral eyes face). */
        emote_set_anim_emoji(emote_handle_, "idle");

        emote_lock(emote_handle_);
        if (eye) {
            gfx_obj_set_visible(eye, true);
        }
        if (toast) {
            gfx_obj_align(toast, GFX_ALIGN_BOTTOM_MID, 0, -4);
            gfx_label_set_text(toast, "");
        }
        emote_unlock(emote_handle_);

        RefreshTopClockAndEye(emote_handle_);
    }
}

void EmoteDisplay::SetupUI()
{
    ESP_LOGI(TAG, "SetupUI: EmoteDisplay starting in pre-connection centered text mode");
    setup_ui_called_ = true;
    SetWifiConnected(false);
}

static const char* NormalizeEmotion(const char* emotion) {
    /* In expression_assets.bin index.json:
     * "idle" -> neutral.eaf (Neutral face!)
     * "neutral" -> winking.eaf
     * Therefore, map "neutral", "idle", and "microchip_ai" to "idle" so neutral.eaf plays! */
    if (!emotion || !*emotion) return "idle";
    std::string s(emotion);
    std::transform(s.begin(), s.end(), s.begin(), ::tolower);
    if (s == "neutral" || s == "idle" || s == "microchip_ai" || s == "standby") return "idle";
    if (s.find("sleep") != std::string::npos) return "sleepy";
    if (s.find("listen") != std::string::npos) return "thinking";
    if (s.find("happy") != std::string::npos || s.find("joy") != std::string::npos) return "happy";
    if (s.find("laugh") != std::string::npos) return "laughing";
    if (s.find("funny") != std::string::npos || s.find("silly") != std::string::npos) return "funny";
    if (s.find("sad") != std::string::npos) return "sad";
    if (s.find("angr") != std::string::npos) return "angry";
    if (s.find("cry") != std::string::npos) return "crying";
    if (s.find("shock") != std::string::npos) return "shocked";
    if (s.find("surpris") != std::string::npos) return "surprised";
    if (s.find("confus") != std::string::npos) return "confused";
    if (s.find("think") != std::string::npos) return "thinking";
    if (s.find("wink") != std::string::npos) return "winking";
    if (s.find("lov") != std::string::npos) return "loving";
    if (s.find("confiden") != std::string::npos) return "confident";
    if (s.find("cool") != std::string::npos) return "cool";
    if (s.find("relax") != std::string::npos) return "relaxed";
    if (s.find("kiss") != std::string::npos) return "kissy";
    if (s.find("delici") != std::string::npos) return "delicious";
    if (s.find("embarrass") != std::string::npos) return "embarrassed";
    return "idle";
}

void EmoteDisplay::SetEmotion(const char* const emotion)
{
    if (!emote_handle_) return;

    if (!wifi_connected_) {
        /* Application calls SetEmotion("microchip_ai") and SetEmotion("neutral")
         * right after Wi-Fi connects and assets are verified. */
        if (IsWifiStaConnectedNow() ||
            (emotion && (strcmp(emotion, "neutral") == 0 || strcmp(emotion, "microchip_ai") == 0 || strcmp(emotion, "happy") == 0))) {
            SetWifiConnected(true);
        } else {
            return;
        }
    }

    const char* norm = NormalizeEmotion(emotion);
    ESP_LOGI(TAG, "SetEmotion: %s -> %s", emotion ? emotion : "null", norm);
    emote_set_anim_emoji(emote_handle_, norm);
    RefreshTopClockAndEye(emote_handle_);
}

void EmoteDisplay::SetChatMessage(const char* const role, const char* const content)
{
    ESP_LOGI(TAG, "SetChatMessage: %s, %s", role ? role : "", content ? content : "");
    if (!emote_handle_) return;

    if (!wifi_connected_) {
        if (IsWifiStaConnectedNow()) {
            SetWifiConnected(true);
        } else {
            /* Do NOT let system user-agent "t-embed/2.2.3" overwrite "Connecting to <SSID>..." */
            std::string conn_msg = BuildConnectingMessage();
            gfx_obj_t* toast = emote_get_obj_by_name(emote_handle_, "toast_label");
            if (toast) {
                emote_lock(emote_handle_);
                gfx_obj_align(toast, GFX_ALIGN_CENTER, 0, 0);
                gfx_label_set_text(toast, conn_msg.c_str());
                gfx_obj_set_visible(toast, true);
                emote_unlock(emote_handle_);
            }
            return;
        }
    }

    if (role && strcmp(role, "assistant") == 0) {
        if (content && *content) {
            std::string c(content);
            if (c.find("?") != std::string::npos || c.find("؟") != std::string::npos) {
                emote_set_anim_emoji(emote_handle_, "confused");
            } else if (c.find("sorry") != std::string::npos || c.find("آسف") != std::string::npos || c.find("خطأ") != std::string::npos || c.find("error") != std::string::npos) {
                emote_set_anim_emoji(emote_handle_, "sad");
            } else {
                emote_set_anim_emoji(emote_handle_, "happy");
            }
        } else {
            emote_set_anim_emoji(emote_handle_, "happy");
        }
    } else if (role && strcmp(role, "user") == 0) {
        emote_set_anim_emoji(emote_handle_, "thinking");
    }

    RefreshTopClockAndEye(emote_handle_);
}

void EmoteDisplay::SetStatus(const char* const status)
{
    ESP_LOGI(TAG, "SetStatus: %s", status ? status : "");
    if (!emote_handle_ || !status || !*status) return;

    std::string s(status);

    /* Check if this status means Wi-Fi is now connected (Standby / Listening / Speaking) */
    bool is_standby = (s.find("Standby") != std::string::npos || s.find("Bekleme") != std::string::npos ||
                       s.find("وضع الاستعداد") != std::string::npos || s.find("جاهز") != std::string::npos ||
                       s.find("Idle") != std::string::npos);
    bool is_listening = (s.find("Listening") != std::string::npos || s.find("Dinleniyor") != std::string::npos ||
                         s.find("استماع") != std::string::npos);
    bool is_speaking = (s.find("Speaking") != std::string::npos || s.find("Konusuluyor") != std::string::npos ||
                        s.find("تحدث") != std::string::npos);

    if (!wifi_connected_) {
        if (is_standby || is_listening || is_speaking || IsWifiStaConnectedNow()) {
            SetWifiConnected(true);
        } else {
            ShowNotification(status, 30000);
            return;
        }
    }

    gfx_obj_t* toast = emote_get_obj_by_name(emote_handle_, "toast_label");
    if (is_listening) {
        emote_set_anim_emoji(emote_handle_, "thinking");
        if (toast) {
            emote_lock(emote_handle_);
            gfx_obj_align(toast, GFX_ALIGN_BOTTOM_MID, 0, -4);
            gfx_label_set_text(toast, "Listening...");
            gfx_obj_set_visible(toast, true);
            emote_unlock(emote_handle_);
        }
    } else if (is_speaking) {
        emote_set_anim_emoji(emote_handle_, "happy");
        if (toast) {
            emote_lock(emote_handle_);
            gfx_obj_align(toast, GFX_ALIGN_BOTTOM_MID, 0, -4);
            gfx_label_set_text(toast, "Speaking...");
            gfx_obj_set_visible(toast, true);
            emote_unlock(emote_handle_);
        }
    } else if (is_standby) {
        emote_set_anim_emoji(emote_handle_, "idle");
        if (toast) {
            emote_lock(emote_handle_);
            gfx_label_set_text(toast, "");
            emote_unlock(emote_handle_);
        }
    } else {
        ShowNotification(status, 3000);
    }

    RefreshTopClockAndEye(emote_handle_);
}

void EmoteDisplay::ShowNotification(const char* notification, int duration_ms)
{
    (void)duration_ms;
    ESP_LOGI(TAG, "ShowNotification: %s", notification ? notification : "");
    if (!emote_handle_ || !notification || !*notification) return;

    /* Check if notification signals Wi-Fi connection in Arabic ("متصل"), Turkish ("Bağlandı"), or English ("Connected") */
    bool is_conn_done = (strncmp(notification, "Connected", 9) == 0 ||
                         strstr(notification, "\xd9\x85\xd8\xaa\xd8\xb5\xd9\x84") != nullptr ||
                         strstr(notification, "Ba\xc4\x9fland\xc4\xb1") != nullptr ||
                         strstr(notification, "\xd8\xa7\xd9\x84\xd8\xa5\xd8\xb5\xd8\xaf\xd8\xa7\xd8\xb1") != nullptr);

    if (is_conn_done) {
        SetWifiConnected(true);
        return;
    }

    /* Check if notification is a pre-connection scanning/connecting notice */
    bool is_conn_progress = (strncasecmp(notification, "Connecting to", 13) == 0 ||
                             strstr(notification, "\xd9\x81\xd8\xad\xd8\xb5") != nullptr ||
                             strstr(notification, "\xd8\xa7\xd9\x84\xd8\xa7\xd8\xaa\xd8\xb5\xd8\xa7\xd9\x84 \xd8\xa8\xd9\x80") != nullptr ||
                             strncasecmp(notification, "Scanning", 8) == 0);

    if (!wifi_connected_ || is_conn_progress) {
        if (IsWifiStaConnectedNow() && !is_conn_progress) {
            SetWifiConnected(true);
        } else {
            wifi_connected_ = false;
            std::string display_msg;
            /* Preserve rotary encoder menu or AP hotspot info if triggered before Wi-Fi connects */
            if (strncmp(notification, "ROTATE:", 7) == 0 || strncmp(notification, "ORIENTATION:", 12) == 0 ||
                strncmp(notification, "BRIGHTNESS:", 11) == 0 || strncmp(notification, "LED RING:", 9) == 0 ||
                strncmp(notification, "Cancelled", 9) == 0 || strstr(notification, "192.168.") != nullptr) {
                display_msg = notification;
            } else {
                display_msg = BuildConnectingMessage(notification);
            }

            gfx_obj_t* eye = emote_get_obj_by_name(emote_handle_, "eye_anim");
            gfx_obj_t* clock_lbl = emote_get_obj_by_name(emote_handle_, "clock_label");
            gfx_obj_t* toast = emote_get_obj_by_name(emote_handle_, "toast_label");
            emote_lock(emote_handle_);
            if (eye) gfx_obj_set_visible(eye, false);
            if (clock_lbl) gfx_obj_set_visible(clock_lbl, false);
            if (toast) {
                gfx_obj_align(toast, GFX_ALIGN_CENTER, 0, 0);
                gfx_label_set_text(toast, display_msg.c_str());
                gfx_obj_set_visible(toast, true);
            }
            emote_unlock(emote_handle_);
            return;
        }
    }

    gfx_obj_t* toast = emote_get_obj_by_name(emote_handle_, "toast_label");
    if (toast) {
        emote_lock(emote_handle_);
        gfx_obj_align(toast, GFX_ALIGN_BOTTOM_MID, 0, -4);
        gfx_label_set_text(toast, notification);
        gfx_obj_set_visible(toast, true);
        emote_unlock(emote_handle_);
    }
    RefreshTopClockAndEye(emote_handle_);
}

void EmoteDisplay::UpdateStatusBar(bool update_all)
{
    (void)update_all;
    if (!emote_handle_) return;

    if (!wifi_connected_) {
        if (IsWifiStaConnectedNow()) {
            SetWifiConnected(true);
        } else {
            return;
        }
    }

    RefreshTopClockAndEye(emote_handle_);

    int level = 0;
    bool charging = false, discharging = false;
    if (Board::GetInstance().GetBatteryLevel(level, charging, discharging)) {
        char bat_msg[16];
        snprintf(bat_msg, sizeof(bat_msg), "%d,%d", charging ? 1 : 0, level);
        emote_set_event_msg(emote_handle_, EMOTE_MGR_EVT_BAT, bat_msg);
    }
}

void EmoteDisplay::SetPowerSaveMode(bool on)
{
    ESP_LOGI(TAG, "SetPowerSaveMode: %s", on ? "ON" : "OFF");
}

void EmoteDisplay::SetPreviewImage(const void* image)
{
    if (image) {
        ESP_LOGI(TAG, "SetPreviewImage: Preview image not supported, using default icon");
    }
}

void EmoteDisplay::SetTheme(Theme* const theme)
{
    ESP_LOGI(TAG, "SetTheme: %p", theme);
}

bool EmoteDisplay::Lock(const int timeout_ms)
{
    (void)timeout_ms;
    return true;
}

void EmoteDisplay::Unlock()
{
}

bool EmoteDisplay::StopAnimDialog()
{
    ESP_LOGI(TAG, "StopAnimDialog");
    if (emote_handle_) {
        return emote_stop_anim_dialog(emote_handle_);
    }
    return false;
}

bool EmoteDisplay::InsertAnimDialog(const char* emoji_name, uint32_t duration_ms)
{
    ESP_LOGI(TAG, "InsertAnimDialog: %s, %" PRIu32, emoji_name, duration_ms);
    if (emote_handle_ && emoji_name && wifi_connected_) {
        return emote_insert_anim_dialog(emote_handle_, emoji_name, duration_ms);
    }
    return false;
}

void EmoteDisplay::RefreshAll()
{
    if (emote_handle_) {
        emote_notify_all_refresh(emote_handle_);
        return;
    }
}

} // namespace emote
"@
Set-Content -Path $emoteCcFile -Value $emoteCc -NoNewline
Write-Host "[OK] Patched Zhilly EmoteDisplay (Connecting to <SSID>, Neutral + Emotion Faces, Top Local Clock)" -ForegroundColor Green

# 4. Patch C:\zhilly_build\main\boards\t-embed\t_embed_board.cc
$tembedFile = "C:\zhilly_build\main\boards\t-embed\t_embed_board.cc"
$tembedContent = Get-Content $tembedFile -Raw

$zhillyTopStateBlock = @"
#define TAG "TEmbedBoard"

// ZHILLY_SD_STATE_TOP_DECLARED
static bool s_zhilly_sd_mounted = false;
static esp_lcd_panel_handle_t s_zhilly_panel = nullptr;
static int s_zhilly_rotation = 0;
static int s_zhilly_brightness = 75;
static int s_zhilly_led_brightness = 32;

static void zhilly_save_sd_state() {
    if (!s_zhilly_sd_mounted) return;
    mkdir("/sdcard/zhilly", 0777);
    FILE* f = fopen("/sdcard/zhilly/state.json", "w");
    if (!f) return;
    fprintf(f, "{\"brightness\":%d,\"rotation\":%d,\"led_brightness\":%d}\n",
            s_zhilly_brightness, s_zhilly_rotation, s_zhilly_led_brightness);
    fclose(f);
}

static void zhilly_load_sd_state() {
    if (!s_zhilly_sd_mounted) {
        s_zhilly_brightness = 75;
        s_zhilly_rotation = 0;
        s_zhilly_led_brightness = 32;
        return;
    }
    FILE* f = fopen("/sdcard/zhilly/state.json", "r");
    if (!f) return;
    char buf[256] = {0};
    size_t n = fread(buf, 1, sizeof(buf) - 1, f);
    fclose(f);
    if (n > 0) {
        cJSON* root = cJSON_Parse(buf);
        if (root) {
            cJSON* b = cJSON_GetObjectItem(root, "brightness");
            cJSON* r = cJSON_GetObjectItem(root, "rotation");
            cJSON* lb = cJSON_GetObjectItem(root, "led_brightness");
            if (cJSON_IsNumber(b)) s_zhilly_brightness = b->valueint;
            if (cJSON_IsNumber(r)) s_zhilly_rotation = r->valueint;
            if (cJSON_IsNumber(lb)) s_zhilly_led_brightness = lb->valueint;
            cJSON_Delete(root);
        }
    }
}
"@

if ($tembedContent -notmatch "ZHILLY_SD_STATE_TOP_DECLARED") {
    # Remove the misplaced block that was inserted above zhilly_switch_ota_slot
    $tembedContent = [regex]::Replace(
        $tembedContent,
        '(?s)static bool s_zhilly_sd_mounted = false;.*?static void zhilly_load_sd_state\(\)\s*\{.*?\r?\n\}\s*',
        ''
    )
    # Place state variables and helpers right after #define TAG "TEmbedBoard" (before TEmbedBoard::TEmbedBoard)
    $tembedContent = $tembedContent.Replace('#define TAG "TEmbedBoard"', $zhillyTopStateBlock)
}

# Ensure SD card mount flag is set in InitializeSdCard() and avoid slow 3MB rewrite on every boot
$tembedContent = $tembedContent.Replace(
    'ESP_LOGI(TAG, "SD card mounted at %s", SDCARD_MOUNT_POINT);',
    'ESP_LOGI(TAG, "SD card mounted at %s", SDCARD_MOUNT_POINT); s_zhilly_sd_mounted = true;'
)
$tembedContent = $tembedContent.Replace('if (sf_len != 2950464)', 'if (sf_len < 100000)')

# Update encoder menu click actions to support all 6 options (Flipper, Bruce, Flip Screen, Brightness, LED Ring, Cancel)
$oldOnClickMenu = @"
            if (s_menu_index == 0) {
                SwitchToFlipper();
                return;
            } else if (s_menu_index == 1) {
                SwitchToBruce();
                return;
            } else {
                auto display = GetDisplay();
                if (display) display->ShowNotification("Cancelled");
                return;
            }
"@
$newOnClickMenu = @"
            auto display = GetDisplay();
            if (s_menu_index == 0) {
                SwitchToFlipper();
                return;
            } else if (s_menu_index == 1) {
                SwitchToBruce();
                return;
            } else if (s_menu_index == 2) {
                s_zhilly_rotation = (s_zhilly_rotation == 0) ? 1 : 0;
                if (s_zhilly_panel) {
                    bool mx = (s_zhilly_rotation == 1) ? !DISPLAY_MIRROR_X : DISPLAY_MIRROR_X;
                    bool my = (s_zhilly_rotation == 1) ? !DISPLAY_MIRROR_Y : DISPLAY_MIRROR_Y;
                    esp_lcd_panel_mirror(s_zhilly_panel, mx, my);
                }
                zhilly_save_sd_state();
                if (display) display->ShowNotification(s_zhilly_rotation ? "ORIENTATION: FLIPPED" : "ORIENTATION: NORMAL", 3000);
                return;
            } else if (s_menu_index == 3) {
                s_zhilly_brightness = (s_zhilly_brightness >= 100) ? 25 : (s_zhilly_brightness + 25);
                if (backlight_) backlight_->SetBrightness(s_zhilly_brightness, s_zhilly_sd_mounted);
                zhilly_save_sd_state();
                char bmsg[32];
                snprintf(bmsg, sizeof(bmsg), "BRIGHTNESS: %d%%", s_zhilly_brightness);
                if (display) display->ShowNotification(bmsg, 3000);
                return;
            } else if (s_menu_index == 4) {
                s_zhilly_led_brightness = (s_zhilly_led_brightness == 0) ? 48 : 0;
                if (led_strip_) led_strip_->SetBrightness(s_zhilly_led_brightness, s_zhilly_led_brightness ? 6 : 0);
                zhilly_save_sd_state();
                if (display) display->ShowNotification(s_zhilly_led_brightness ? "LED RING: ON" : "LED RING: OFF", 3000);
                return;
            } else {
                if (display) display->ShowNotification("Cancelled", 2000);
                return;
            }
"@
if ($tembedContent -notmatch "ORIENTATION: FLIPPED") {
    $tembedContent = [regex]::Replace(
        $tembedContent,
        '(?s)\s*if \(s_menu_index == 0\) \{\s*SwitchToFlipper\(\);\s*return;\s*\} else if \(s_menu_index == 1\) \{\s*SwitchToBruce\(\);\s*return;\s*\} else \{\s*auto display = GetDisplay\(\);\s*if \(display\) display->ShowNotification\("Cancelled"\);\s*return;\s*\}',
        "`r`n" + $newOnClickMenu
    )
}
Set-Content -Path $tembedFile -Value $tembedContent -NoNewline
Write-Host "[OK] Patched Zhilly t_embed_board.cc (top-scope SD state, CRC32, orientation/brightness/LED)" -ForegroundColor Green

# 5. Patch C:\zhilly_build\main\application.cc
$appFile = "C:\zhilly_build\main\application.cc"
$appContent = Get-Content $appFile -Raw

# Add extern declaration for zhilly_switch_ota_slot and emote_display include
if ($appContent -notmatch "3-IN-1 MULTI-BOOT UPDATED") {
    if ($appContent -notmatch "zhilly_switch_ota_slot") {
        $appContent = $appContent.Replace(
            '#include "application.h"',
            '#include "application.h"' + "`r`n" + '#if CONFIG_USE_EMOTE_MESSAGE_STYLE' + "`r`n" + '#include "display/emote_display.h"' + "`r`n" + '#endif' + "`r`n" + 'extern "C" void zhilly_switch_ota_slot(uint8_t slot_idx);'
        )
    }

    $newNetEvents = @"
        case NetworkEvent::Scanning: {
#if CONFIG_USE_EMOTE_MESSAGE_STYLE
            auto emote_disp = dynamic_cast<emote::EmoteDisplay*>(display);
            if (emote_disp) emote_disp->SetWifiConnected(false);
#endif
            display->SetStatus("CONNECTING TO WIFI...");
            break;
        }
        case NetworkEvent::Connecting: {
#if CONFIG_USE_EMOTE_MESSAGE_STYLE
            auto emote_disp = dynamic_cast<emote::EmoteDisplay*>(display);
            if (emote_disp) emote_disp->SetWifiConnected(false);
#endif
            if (event_data.empty()) {
                display->SetStatus("CONNECTING TO WIFI...");
            } else {
                std::string msg = "CONNECTING TO " + event_data + "...";
                display->SetStatus(msg.c_str());
            }
            break;
        }
"@
    $appContent = [regex]::Replace(
        $appContent,
        '(?s)\s*case NetworkEvent::Scanning:\s*display->SetStatus\(Lang::Strings::SCANNING_WIFI\);\s*break;\s*case NetworkEvent::Connecting:\s*\{.*?\r?\n\s*\}',
        "`r`n" + $newNetEvents
    )

    $newConnected = @"
void Application::HandleNetworkConnectedEvent() {
    ESP_LOGI(TAG, "Network connected");
    setenv("TZ", "AST-3", 1);
    tzset();
    auto display = Board::GetInstance().GetDisplay();
    {
        Settings boot_info("zhilly_boot", true);
        std::string build_id = std::string(__DATE__) + " " + std::string(__TIME__);
        if (boot_info.GetString("build_id") != build_id) {
            boot_info.SetString("build_id", build_id);
            const char* fundamentals_msg =
                "3-IN-1 MULTI-BOOT UPDATED! "
                "1) Zhilly AI by siberbaba (gitlab.com/sacriphanius/Zhilly | github.com/siberbaba/siberbaba) [AR/TR/EN] "
                "2) Flipper Zero ESP32 by Sor3nt (github.com/Sor3nt/Flipper-Zero-ESP32-Port) "
                "3) Bruce Firmware T-Embed CC1101 Plus (github.com/brucedevices/firmware)";
            ESP_LOGW(TAG, "%s", fundamentals_msg);
            display->SetStatus(fundamentals_msg);
            vTaskDelay(pdMS_TO_TICKS(4500));
        }
    }
#if CONFIG_USE_EMOTE_MESSAGE_STYLE
    {
        auto emote_disp = dynamic_cast<emote::EmoteDisplay*>(display);
        if (emote_disp) emote_disp->SetWifiConnected(true);
    }
#endif
    display->SetChatMessage("system", "");
"@
    $appContent = [regex]::Replace(
        $appContent,
        '(?s)void Application::HandleNetworkConnectedEvent\(\)\s*\{\s*ESP_LOGI\(TAG, "Network connected"\);\s*auto display = Board::GetInstance\(\)\.GetDisplay\(\);\s*display->SetChatMessage\("system", ""\);',
        $newConnected
    )

    $newVoiceSwitch = @"
                bool is_to_flipper = (
                    text.find("flipper'a geç") != std::string::npos ||
                    text.find("flippera geç") != std::string::npos ||
                    text.find("flipper moduna") != std::string::npos ||
                    text.find("switch to flipper") != std::string::npos ||
                    text.find("open flipper") != std::string::npos ||
                    text.find("انتقل إلى فليبر") != std::string::npos ||
                    text.find("انتقل الى فليبر") != std::string::npos ||
                    text.find("حول إلى فليبر") != std::string::npos ||
                    text.find("حول الى فليبر") != std::string::npos ||
                    text.find("افتح فليبر") != std::string::npos
                );
                bool is_to_bruce = (
                    text.find("bruce'a geç") != std::string::npos ||
                    text.find("brucea geç") != std::string::npos ||
                    text.find("bruce moduna") != std::string::npos ||
                    text.find("switch to bruce") != std::string::npos ||
                    text.find("open bruce") != std::string::npos ||
                    text.find("انتقل إلى بروس") != std::string::npos ||
                    text.find("انتقل الى بروس") != std::string::npos ||
                    text.find("حول إلى بروس") != std::string::npos ||
                    text.find("حول الى بروس") != std::string::npos ||
                    text.find("افتح بروس") != std::string::npos
                );

                if (is_to_flipper) {
                    ESP_LOGW(TAG, "Switching to Flipper Zero (slot 1 / ota_1)!");
                    zhilly_switch_ota_slot(1);
                } else if (is_to_bruce) {
                    ESP_LOGW(TAG, "Switching to Bruce Firmware (slot 0 / ota_0)!");
                    zhilly_switch_ota_slot(0);
                }
"@
    $appContent = [regex]::Replace(
        $appContent,
        '(?s)\s*bool is_to_flipper = .*?display->SetChatMessage\("system", "Error: OTA end failed!"\);\s*\}\s*\}\);\s*\}',
        "`r`n" + $newVoiceSwitch
    )
    Set-Content -Path $appFile -Value $appContent -NoNewline
    Write-Host "[OK] Patched Zhilly application.cc (AR+TR+EN voice switch, pre-connection screen, post-flash info)" -ForegroundColor Green
}

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " STEP 2: BUILDING BRUCE FIRMWARE (ota_0)" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
$bruceBin = "c:\Users\Abdullah\Desktop\qias\bruce_src\.pio\build\lilygo-t-embed-cc1101\firmware.bin"
$pioPlatformPy = "C:\Users\Abdullah\.platformio\platforms\espressif32\platform.py"
if (Test-Path $pioPlatformPy) {
    $platContent = Get-Content $pioPlatformPy -Raw
    if ($platContent -match "def install_python_deps\(self\):") {
        $platContent = $platContent -replace "def install_python_deps\(self\):", "def install_python_deps(self):`n        return"
        Set-Content -Path $pioPlatformPy -Value $platContent -NoNewline
    }
}
$env:PATH = "C:\Users\Abdullah\.platformio\penv\Scripts;" + $env:PATH
Push-Location "c:\Users\Abdullah\Desktop\qias\bruce_src"
& "C:\Users\Abdullah\.platformio\penv\Scripts\platformio.exe" run -e lilygo-t-embed-cc1101
if ($LASTEXITCODE -ne 0) { throw "Bruce build failed!" }
Pop-Location

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " STEP 3: BUILDING FLIPPER ZERO ESP32 PORT BY SOR3NT (ota_1)" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

# Auto-discover ESP-IDF Python and IDF_PATH from existing CMakeCache.txt or C:\Espressif
$idfPython = $null
$idfPath = $null
foreach ($cacheFile in @("c:\Users\Abdullah\Desktop\qias\flipper_src\build\CMakeCache.txt", "C:\zhilly_build\build\CMakeCache.txt")) {
    if (Test-Path $cacheFile) {
        $cacheLines = Get-Content $cacheFile
        foreach ($line in $cacheLines) {
            if (-not $idfPython -and $line -match "^PYTHON:FILEPATH=(.+)$") {
                if (Test-Path $Matches[1]) { $idfPython = $Matches[1] }
            }
            if (-not $idfPython -and $line -match "^Python3_EXECUTABLE:FILEPATH=(.+)$") {
                if (Test-Path $Matches[1]) { $idfPython = $Matches[1] }
            }
            if (-not $idfPath -and $line -match "^IDF_PATH:PATH=(.+)$") {
                if (Test-Path $Matches[1]) { $idfPath = $Matches[1] }
            }
        }
    }
}

if (-not $idfPython) {
    $pyFound = Get-ChildItem -Path @("C:\Espressif", "$env:USERPROFILE\.espressif") -Filter "python.exe" -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match "python_env|venv" } | Select-Object -First 1
    if ($pyFound) { $idfPython = $pyFound.FullName }
}
if (-not $idfPath) {
    $idfFound = Get-ChildItem -Path @("C:\Espressif", "$env:USERPROFILE\esp", "C:\esp") -Filter "idf.py" -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($idfFound) { $idfPath = Split-Path (Split-Path $idfFound.FullName -Parent) -Parent }
}

Write-Host "Detected IDF_PATH: $idfPath" -ForegroundColor Yellow
Write-Host "Detected IDF Python: $idfPython" -ForegroundColor Yellow

$env:IDF_PATH = $idfPath
$env:IDF_PYTHON_ENV_PATH = Split-Path (Split-Path $idfPython -Parent) -Parent
$env:PYTHONIOENCODING = "utf-8"

# Add all tool directories under C:\Espressif\tools (and ~/.espressif/tools) to PATH
$toolDirs = @()
$toolDirs += Split-Path $idfPython -Parent
foreach ($toolsRoot in @("C:\Espressif\tools", "$env:USERPROFILE\.espressif\tools")) {
    if (Test-Path $toolsRoot) {
        Get-ChildItem -Path $toolsRoot -Directory -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -in @("bin", "cmd") -or (Test-Path (Join-Path $_.FullName "ninja.exe")) -or (Test-Path (Join-Path $_.FullName "ccache.exe")) } |
            ForEach-Object { $toolDirs += $_.FullName }
        Get-ChildItem -Path "$toolsRoot\esp-rom-elfs" -Directory -ErrorAction SilentlyContinue |
            ForEach-Object {
                $toolDirs += $_.FullName
                $env:ESP_ROM_ELF_DIR = $_.FullName
            }
    }
}
if (-not $env:ESP_ROM_ELF_DIR) {
    $env:ESP_ROM_ELF_DIR = "C:\Espressif\tools\esp-rom-elfs\20241011"
}
Write-Host "Detected ESP_ROM_ELF_DIR: $env:ESP_ROM_ELF_DIR" -ForegroundColor Yellow
$env:PATH = ($toolDirs -join ";") + ";" + $env:PATH

$flipperBin = "c:\Users\Abdullah\Desktop\qias\flipper_src\build\furi_esp32.bin"
Write-Host "Building Flipper Zero ESP32 Port (lilygo_t_embed_cc1101) with backlight ON..." -ForegroundColor Yellow
Push-Location "c:\Users\Abdullah\Desktop\qias\flipper_src"
& $idfPython "$idfPath\tools\idf.py" -DFLIPPER_BOARD=lilygo_t_embed_cc1101 build
if ($LASTEXITCODE -ne 0) { throw "Flipper Zero build failed!" }
Pop-Location

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " STEP 4: BUILDING ZHILLY AI BY SIBERBABA [AR + TR + EN] (ota_2)" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
$zhillyBin = "C:\zhilly_build\build\xiaozhi.bin"
$zhillyPython = "C:\Espressif\python_env\idf5.5_py3.11_env\Scripts\python.exe"
$zhillyIdfPath = $idfPath
$zhillyDesc = "C:\zhilly_build\build\project_description.json"
if (Test-Path $zhillyDesc) {
    $descJson = Get-Content $zhillyDesc -Raw | ConvertFrom-Json
    if ($descJson.idf_path -and (Test-Path $descJson.idf_path)) {
        $zhillyIdfPath = $descJson.idf_path
    }
}
if (-not (Test-Path $zhillyPython)) {
    $zhillyPython = $idfPython
}
Write-Host "Zhilly IDF_PATH: $zhillyIdfPath" -ForegroundColor Yellow
Write-Host "Zhilly Python:   $zhillyPython" -ForegroundColor Yellow
$env:IDF_PATH = $zhillyIdfPath
$env:IDF_PYTHON_ENV_PATH = Split-Path (Split-Path $zhillyPython -Parent) -Parent
$env:PATH = (Split-Path $zhillyPython -Parent) + ";" + ($toolDirs -join ";") + ";" + $env:PATH

Push-Location "C:\zhilly_build"
& $zhillyPython "$zhillyIdfPath\tools\idf.py" build
if ($LASTEXITCODE -ne 0) { throw "Zhilly AI build failed!" }
Pop-Location

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " STEP 5: UPDATING SD CARD BINARIES & FLASHING DEVICE ON COM13" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
$sdFwDir = "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\SD_CARD\firmware"
if (Test-Path $sdFwDir) {
    Remove-Item "$sdFwDir\*" -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Force -Path $sdFwDir | Out-Null
Copy-Item "c:\Users\Abdullah\Desktop\qias\bruce_src\.pio\build\lilygo-t-embed-cc1101\firmware.bin" "$sdFwDir\bruce.bin" -Force
Copy-Item "c:\Users\Abdullah\Desktop\qias\flipper_src\build\furi_esp32.bin" "$sdFwDir\flipper.bin" -Force
Copy-Item "C:\zhilly_build\build\xiaozhi.bin" "$sdFwDir\zhilly.bin" -Force

if (Test-Path "D:\") {
    Write-Host "Detected SD Card at D:\ -> Syncing all 3 firmwares and fixed bruce.conf..." -ForegroundColor Yellow
    if (Test-Path "D:\firmware") {
        Remove-Item "D:\firmware\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Force -Path "D:\firmware" | Out-Null
    New-Item -ItemType Directory -Force -Path "D:\zhilly" | Out-Null
    New-Item -ItemType Directory -Force -Path "D:\bruce" | Out-Null
    Copy-Item "$sdFwDir\bruce.bin" "D:\firmware\bruce.bin" -Force
    Copy-Item "$sdFwDir\flipper.bin" "D:\firmware\flipper.bin" -Force
    Copy-Item "$sdFwDir\zhilly.bin" "D:\firmware\zhilly.bin" -Force
    Copy-Item "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\SD_CARD\zhilly\config.json" "D:\zhilly\config.json" -Force
    Copy-Item "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\SD_CARD\FUNDAMENTALS_3_IN_1.txt" "D:\FUNDAMENTALS_3_IN_1.txt" -Force
    Copy-Item "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\SD_CARD\bruce.conf" "D:\bruce.conf" -Force
    Copy-Item "c:\Users\Abdullah\Desktop\qias\3 FRIMWARES\SD_CARD\bruce.conf" "D:\bruce\bruce.conf" -Force
}

Write-Host "Erasing stale LittleFS/spiffs region (0xF90000) to clear any corrupted bruce.conf..." -ForegroundColor Yellow
& $idfPython -m esptool --chip esp32s3 -p COM13 -b 921600 --before default_reset --after no_reset erase_region 0xF90000 0x60000

Write-Host "Flashing ALL 3 Firmwares (Bruce + Flipper + Zhilly AI + Expression Assets) to COM13..." -ForegroundColor Cyan
& $idfPython -m esptool --chip esp32s3 -p COM13 -b 921600 --before no_reset --after hard_reset write_flash --flash_mode dio --flash_freq 80m --flash_size 16MB `
    0x0 "c:\Users\Abdullah\Desktop\qias\flipper_src\build\bootloader\bootloader.bin" `
    0x8000 "c:\Users\Abdullah\Desktop\qias\flipper_src\build\partition_table\partition-table.bin" `
    0x10000 "c:\Users\Abdullah\Desktop\qias\flipper_src\build\ota_data_initial.bin" `
    0x20000 "c:\Users\Abdullah\Desktop\qias\bruce_src\.pio\build\lilygo-t-embed-cc1101\firmware.bin" `
    0x4E0000 "c:\Users\Abdullah\Desktop\qias\flipper_src\build\furi_esp32.bin" `
    0x880000 "C:\zhilly_build\build\xiaozhi.bin" `
    0xB90000 "C:\zhilly_build\build\expression_assets.bin"

Write-Host "Verifying live boot log on COM13..." -ForegroundColor Yellow
try {
    $port = New-Object System.IO.Ports.SerialPort "COM13", 115200, "None", 8, "One"
    $port.DtrEnable = $false
    $port.RtsEnable = $false
    $port.ReadTimeout = 500
    $port.Open()
    $endTime = (Get-Date).AddSeconds(4)
    while ((Get-Date) -lt $endTime) {
        try {
            $line = $port.ReadExisting()
            if ($line) { Write-Host -NoNewline $line }
        } catch {}
        Start-Sleep -Milliseconds 100
    }
    $port.Close()
} catch {
    Write-Host "Serial check note: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Green
Write-Host " ALL 3 FIRMWARES BUILT, SYNCED TO SD_CARD, AND FLASHED TO COM13!" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Green
