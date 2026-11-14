/*
 * firmware_switch_app.c - Standalone Flipper Application (.fap)
 * Allows switching between Flipper Zero, Bruce, and Zhilly AI
 * Run directly from Applications -> Tools -> Firmware Switcher!
 */

#include <furi.h>
#include <furi_hal.h>
#include <gui/gui.h>
#include <gui/view_dispatcher.h>
#include <gui/modules/submenu.h>
#include <gui/modules/popup.h>
#include <storage/storage.h>
#include "../firmware_switch.h"

#define TAG "FirmwareSwitchApp"

typedef enum {
    SubmenuIndexSwitchBruce,
    SubmenuIndexSwitchZhilly,
    SubmenuIndexSettings,
    SubmenuIndexAbout,
} SubmenuIndex;

typedef struct {
    Gui* gui;
    ViewDispatcher* view_dispatcher;
    Submenu* submenu;
    Popup* popup;
} FirmwareSwitchApp;

static void submenu_callback(void* context, uint32_t index) {
    FirmwareSwitchApp* app = context;

    switch (index) {
        case SubmenuIndexSwitchBruce: {
            if (!firmware_switch_is_available(TARGET_FIRMWARE_BRUCE)) {
                popup_set_header(app->popup, "Missing File!", 64, 10, AlignCenter, AlignTop);
                popup_set_text(app->popup, "Place bruce.bin into\n/sdcard/firmware/", 64, 30, AlignCenter, AlignTop);
                view_dispatcher_switch_to_view(app->view_dispatcher, 1);
                return;
            }
            popup_set_header(app->popup, "Switching...", 64, 10, AlignCenter, AlignTop);
            popup_set_text(app->popup, "Loading Bruce Firmware\nPlease wait...", 64, 30, AlignCenter, AlignTop);
            view_dispatcher_switch_to_view(app->view_dispatcher, 1);
            furi_delay_ms(1000);
            firmware_switch_to(TARGET_FIRMWARE_BRUCE);
            break;
        }

        case SubmenuIndexSwitchZhilly: {
            if (!firmware_switch_is_available(TARGET_FIRMWARE_ZHILLY)) {
                popup_set_header(app->popup, "Missing File!", 64, 10, AlignCenter, AlignTop);
                popup_set_text(app->popup, "Place zhilly.bin into\n/sdcard/firmware/", 64, 30, AlignCenter, AlignTop);
                view_dispatcher_switch_to_view(app->view_dispatcher, 1);
                return;
            }
            popup_set_header(app->popup, "Switching...", 64, 10, AlignCenter, AlignTop);
            popup_set_text(app->popup, "Loading ZHILLY AI\nPlease wait...", 64, 30, AlignCenter, AlignTop);
            view_dispatcher_switch_to_view(app->view_dispatcher, 1);
            furi_delay_ms(1000);
            firmware_switch_to(TARGET_FIRMWARE_ZHILLY);
            break;
        }

        case SubmenuIndexAbout: {
            popup_set_header(app->popup, "3-in-1 Multi-Boot", 64, 5, AlignCenter, AlignTop);
            popup_set_text(app->popup, "LilyGO T-Embed Plus\nFlipper + Bruce + Zhilly\nAbdullah & Team Gemini", 64, 25, AlignCenter, AlignTop);
            view_dispatcher_switch_to_view(app->view_dispatcher, 1);
            break;
        }

        default:
            break;
    }
}

static uint32_t previous_view_callback(void* context) {
    UNUSED(context);
    return 0; // Back to submenu
}

int32_t firmware_switch_app_main(void* p) {
    UNUSED(p);
    FirmwareSwitchApp* app = malloc(sizeof(FirmwareSwitchApp));

    // Open GUI
    app->gui = furi_record_open(RECORD_GUI);
    app->view_dispatcher = view_dispatcher_alloc();
    view_dispatcher_enable_queue(app->view_dispatcher);
    view_dispatcher_attach_to_gui(app->view_dispatcher, app->gui, ViewDispatcherTypeFullscreen);

    // Submenu
    app->submenu = submenu_alloc();
    submenu_set_header(app->submenu, "Multi-Boot Switcher");
    submenu_add_item(app->submenu, "Switch to Bruce", SubmenuIndexSwitchBruce, submenu_callback, app);
    submenu_add_item(app->submenu, "Switch to ZHILLY AI", SubmenuIndexSwitchZhilly, submenu_callback, app);
    submenu_add_item(app->submenu, "About 3-in-1", SubmenuIndexAbout, submenu_callback, app);
    view_dispatcher_add_view(app->view_dispatcher, 0, submenu_get_view(app->submenu));

    // Popup
    app->popup = popup_alloc();
    popup_set_callback(app->popup, (PopupCallback)previous_view_callback);
    popup_set_context(app->popup, app);
    view_dispatcher_add_view(app->view_dispatcher, 1, popup_get_view(app->popup));

    view_dispatcher_switch_to_view(app->view_dispatcher, 0);

    // Run event loop
    view_dispatcher_run(app->view_dispatcher);

    // Cleanup
    view_dispatcher_remove_view(app->view_dispatcher, 0);
    view_dispatcher_remove_view(app->view_dispatcher, 1);
    submenu_free(app->submenu);
    popup_free(app->popup);
    view_dispatcher_free(app->view_dispatcher);
    furi_record_close(RECORD_GUI);
    free(app);

    return 0;
}

