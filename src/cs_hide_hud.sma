#include <amxmodx>

#define PLUGIN "Airships: Hide Hud (CS)"
#define VERSION "0.1"

// Those constants were not defined in 1.8.2
#define HIDE_HEALTH     (1<<3)
#define HIDE_MONEY      (1<<5)
#define HIDE_CROSSHAIR  (1<<6)
const HIDE_UNNEEDED = HIDE_HEALTH|HIDE_MONEY|HIDE_CROSSHAIR;

new g_msgHideWeapon;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, "Mia2904");

    g_msgHideWeapon = get_user_msgid("HideWeapon");
    register_message(g_msgHideWeapon, "msg_HideWeapon");
    register_event("ResetHUD", "ev_ResetHUD", "b");
}

public msg_HideWeapon(iDest, iEnt, iId)
{
    set_msg_arg_int(1, ARG_BYTE, HIDE_UNNEEDED);
}

public ev_ResetHUD(iId)
{
    message_begin(MSG_ONE_UNRELIABLE, g_msgHideWeapon, _, iId);
    write_byte(HIDE_UNNEEDED);
    message_end();
}
