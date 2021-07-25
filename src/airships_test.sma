#include <amxmodx>
#include <airships>
#include <engine>

#define PLUGIN "Airships Test"
#define VERSION "0.1"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, "Mia2904");
    
    register_clcmd("say airship", "clcmd_Airship");
}

public clcmd_Airship(iId)
{
    new Float:vOrigin[3], Float:vAngles[3];
    entity_get_vector(iId, EV_VEC_origin, vOrigin);
    entity_get_vector(iId, EV_VEC_angles, vAngles);

    // Stuck the player in ground
    vOrigin[2] -= 5.0;
    entity_set_origin(iId, vOrigin);
    vOrigin[2] += 300.0;
    
    as_spawn(iId, vOrigin, vAngles, 0.0, true, 0.0, false, false);
}