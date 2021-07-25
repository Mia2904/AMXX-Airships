// This plugin creates an "explosion" animation when an airship dies
// It also prevents the camera from disappearing until the animation has finished (~4 seconds)
#include <amxmodx>
#include <airships>
#include <engine>
#include <xs>

#define PLUGIN "Airships Explosion"
#define VERSION "0.1"

#pragma semicolon 1

new const szExplosionSprite[] = "sprites/airship_exp.spr";
new const szExplosionSound[] = "airship/explosion.wav";

public plugin_precache()
{
    precache_sound(szExplosionSound);
    precache_model(szExplosionSprite);
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, "Mia2904");
}

public as_Killed_Post(iEnt, iPlayer, iKillerEnt, iKillerPlayer)
{
    static iCameraEnt;
    iCameraEnt = entity_get_edict(iEnt, EV_ENT_cameraent);

    if (!iCameraEnt)
        iCameraEnt = as_set_camera(entity_get_edict(iEnt, EV_ENT_owner), true);
    else
    {
        entity_set_vector(iCameraEnt, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 });
        entity_set_vector(iCameraEnt, EV_VEC_avelocity, Float:{ 0.0, 0.0, 0.0 });
    }

    // Hack: Delay the next think of the camera to prevent it from dissapearing
    static Float:fCurrentTime;
    fCurrentTime = halflife_time();
    entity_set_float(iCameraEnt, EV_FL_nextthink, fCurrentTime + 4.0);

    static Float:vOrigin[3], Float:vAngles[3], Float:vUpVector[3];
    entity_get_vector(iEnt, EV_VEC_origin, vOrigin);
    entity_get_vector(iEnt, EV_VEC_angles, vAngles);
    angle_vector(vAngles, ANGLEVECTOR_UP, vUpVector);
    xs_vec_mul_scalar(vUpVector, 180.0, vUpVector);
    xs_vec_add(vOrigin, vUpVector, vOrigin);
    create_explosion(vOrigin, fCurrentTime);
}

create_explosion(Float:vOrigin[3], Float:fCurrentTime)
{
    new iEnt = create_entity("env_sprite");
    entity_set_origin(iEnt, vOrigin);
    entity_set_model(iEnt, szExplosionSprite);
    entity_set_float(iEnt, EV_FL_scale, 3.0);
    entity_set_float(iEnt, EV_FL_animtime, fCurrentTime);
    entity_set_float(iEnt, EV_FL_framerate, 6.0);
    entity_set_int(iEnt, EV_INT_spawnflags, SF_SPRITE_STARTON|SF_SPRITE_ONCE);
    DispatchSpawn(iEnt);
    emit_sound(iEnt, CHAN_BODY, szExplosionSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    set_task(4.0, "task_remove_sprite", iEnt);
}

public task_remove_sprite(iEnt)
{
    if (is_valid_ent(iEnt))
        remove_entity(iEnt);
}