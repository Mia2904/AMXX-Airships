/*  
    Airships core.
    (C) 2021. By Mia2904.
    Lima, Peru.

    Licence: MIT.
*/

#include <amxmodx>
#include <airships>
#include <engine>
#include <hamsandwich>
#include <xs>

#define PLUGIN "Airships Core"
#define VERSION "0.1"

#pragma semicolon 1

new const szAirshipModel[] = "models/fallout_car.mdl";

new const Float:g_vMins[3] = { -60.0, -60.0, 0.0 };
new const Float:g_vMaxs[3] = { 60.0, 60.0, 60.0 };

const Float:AIRSHIP_THINK_INTERVAL = 0.1;
const Float:CAMERA_THINK_INTERVAL = 0.3;

new const szFireSound[] = "airship/fire.wav";
new const szBarrelRollSound[] = "airship/barrelroll.wav";

new Float:g_fMaxSpeed;
new Float:g_fMaxUpSpeed;
new Float:g_fMaxFallSpeed;
new Float:g_fAccceleration;
new Float:g_fDeceleration;
new Float:g_fVerticalAcceleration;
new Float:g_fGravity;
new Float:g_fMinTurningAngle;
new Float:g_fMaxRotatingAngle;
new Float:g_fMaxPitchAngle;
new Float:g_fAngleRollMul;
new Float:g_fAngleYawMul;
new Float:g_fAnglePitchMul;
new Float:g_fMaxPitchSpeed;
new Float:g_fMaxRollSpeed;
new Float:g_fFireInterval;
new Float:g_fLaserDamage;
new Float:g_fCrashDamage;
new Float:g_fCrashTimeInterval;
new Float:g_fDefaultHp;
new Float:g_fCameraDistance;

new g_cvar_maxspeed;
new g_cvar_max_up_speed;
new g_cvar_max_fall_speed;
new g_cvar_acceleration;
new g_cvar_deceleration;
new g_cvar_vertical_acceleration;
new g_cvar_gravity;
new g_cvar_min_turning_angle;
new g_cvar_max_rotating_angle;
new g_cvar_max_pitch_angle;
new g_cvar_angle_roll_mul;
new g_cvar_angle_yaw_mul;
new g_cvar_angle_pitch_mul;
new g_cvar_max_pitch_speed;
new g_cvar_max_roll_speed;
new g_cvar_fire_interval;
new g_cvar_laser_damage;
new g_cvar_crash_damage;
new g_cvar_crash_interval;
new g_cvar_default_hp;
new g_cvar_camera_distance;

new g_iSprLaser;

new g_fwLaserHitPre;
new g_fwLaserHitPost;
new g_fwKilledPre;
new g_fwKilledPost;
new g_fwCrashPre;
new g_fwCrashPost;

public plugin_precache()
{
    precache_model(szAirshipModel);
    precache_sound(szFireSound);
    precache_sound(szBarrelRollSound);
    g_iSprLaser = precache_model("sprites/laserbeam.spr");
}

public plugin_natives()
{
    register_native("as_spawn", "native_spawn", 0);
    register_native("as_set_camera", "native_set_camera", 0);
    register_native("as_get_user_airship", "native_get_airship", 0);
    register_native("as_set_user_airship", "native_set_airship", 0);
}

public native_spawn(iPlugin, iParamCount)
{
    new iPlayer, Float:vOrigin[3], Float:vAngles[3], bCanShoot, bCamera, bFreeMove, Float:fHealth, Float:fAttack, iRetEnt, iRetCameraEnt;

    iPlayer = get_param(1);
    get_array_f(2, vOrigin, 3);
    get_array_f(3, vAngles, 3);
    fHealth = get_param_f(4);
    bCanShoot = get_param(5);
    fAttack = get_param_f(6);
    bCamera = get_param(7);
    bFreeMove = get_param(8);

    create_airship(iPlayer, vOrigin, vAngles, fHealth, bCanShoot, fAttack, bCamera, bFreeMove, iRetEnt, iRetCameraEnt);

    set_param_byref(9, iRetEnt);
    set_param_byref(10, iRetCameraEnt);

    return 1;
}

public native_set_camera(iPlugin, iParamCount)
{
    new iPlayer = get_param(1);
    new bCamera = get_param(2);

    new iEnt, iCameraEnt;
    iEnt = find_ent_by_owner(-1, AIRSHIP_CLASSNAME, iPlayer);

    if (!iEnt)
    {
        log_error(AMX_ERR_NATIVE, "Player id (%d) got no airship. Can't set camera.", iPlayer);
        return 0;
    }

    iCameraEnt = entity_get_edict(iEnt, EV_ENT_cameraent);

    if (bCamera)
    {
        if (!iCameraEnt || !is_valid_ent(iCameraEnt))
            iCameraEnt = create_camera(iEnt, iPlayer);
        else
            attach_view(iPlayer, iCameraEnt);
        
        return iCameraEnt;
    }

    if (iCameraEnt && is_valid_ent(iCameraEnt))
    {
        entity_set_int(iCameraEnt, EV_INT_flags, entity_get_int(iCameraEnt, EV_INT_flags)|FL_KILLME);
        entity_set_edict(iEnt, EV_ENT_cameraent, 0);
    }

    attach_view(iPlayer, iEnt);

    return 0;
}

public native_get_airship(iPlugin, iParamCount)
{
    return find_ent_by_owner(-1, AIRSHIP_CLASSNAME, get_param(1));
}

public native_set_airship(iPlugin, iParamCount)
{
    new iPlayer = get_param(1);
    new iEnt = get_param(2);

    if (!iEnt || !is_valid_ent(iEnt))
    {
        log_error(AMX_ERR_NATIVE, "Invalid entity (%d).", iEnt);
        return 0;
    }
    
    entity_set_edict(iEnt, EV_ENT_owner, iPlayer);

    new iCameraEnt = entity_get_edict(iEnt, EV_ENT_cameraent);
    if (iCameraEnt)
        attach_view(iPlayer, iCameraEnt);
    else
        attach_view(iPlayer, iEnt);
    
    return 1;
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, "Mia2904");
    
    register_think(AIRSHIP_CLASSNAME, "fw_AirshipThink");
    register_think(CAMERA_CLASSNAME, "fw_CameraThink");

    register_touch("*", AIRSHIP_CLASSNAME, "fw_AirshipTouch");

    RegisterHam(Ham_Killed, "info_target", "fw_AirshipKilled", 0);
    
    g_cvar_maxspeed = register_cvar("as_max_speed", "700.0");
    g_cvar_max_up_speed = register_cvar("as_max_up_speed", "200.0");
    g_cvar_max_fall_speed = register_cvar("as_max_fall_speed", "150.0");
    g_cvar_acceleration = register_cvar("as_acceleration", "70.0");
    g_cvar_deceleration = register_cvar("as_deceleration", "30.0");
    g_cvar_vertical_acceleration = register_cvar("as_up_acceleration", "15.0");
    g_cvar_gravity = register_cvar("as_gravity", "20.0");
    g_cvar_min_turning_angle = register_cvar("as_min_turning_angle", "0.0");
    g_cvar_max_rotating_angle = register_cvar("as_max_rotating_angle", "50.0");
    g_cvar_max_pitch_angle = register_cvar("as_max_pitch_angle", "50.0");
    g_cvar_angle_roll_mul = register_cvar("as_angle_roll_mul", "15.0");
    g_cvar_angle_yaw_mul = register_cvar("as_angle_yaw_mul", "80.0");
    g_cvar_angle_pitch_mul = register_cvar("as_angle_pitch_mul", "10.0");
    g_cvar_max_pitch_speed = register_cvar("as_max_pitch_speed", "50.0");
    g_cvar_max_roll_speed = register_cvar("as_max_roll_speed", "30.0");
    g_cvar_fire_interval = register_cvar("as_fire_interval", "0.4");
    g_cvar_laser_damage = register_cvar("as_default_attack", "100.0");
    g_cvar_crash_damage = register_cvar("as_crash_damage", "200.0");
    g_cvar_crash_interval = register_cvar("as_crash_interval", "4.0");
    g_cvar_default_hp = register_cvar("as_default_hp", "500.0");
    g_cvar_camera_distance = register_cvar("as_camera_min_distance", "400.0");

    g_fwLaserHitPre = CreateMultiForward("as_LaserHit_Pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_FLOAT);
    g_fwLaserHitPost = CreateMultiForward("as_LaserHit_Post", ET_IGNORE, FP_CELL, FP_CELL, FP_FLOAT);
    g_fwKilledPre = CreateMultiForward("as_Killed_Pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
    g_fwKilledPost = CreateMultiForward("as_Killed_Post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
    g_fwCrashPre = CreateMultiForward("as_Crash_Pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_FLOAT);
    g_fwCrashPost = CreateMultiForward("as_Crash_Post", ET_IGNORE, FP_CELL, FP_CELL, FP_FLOAT);
}

cache_cvars()
{
    g_fMaxSpeed = get_pcvar_float(g_cvar_maxspeed);
    g_fMaxUpSpeed = get_pcvar_float(g_cvar_max_up_speed);
    g_fMaxFallSpeed = get_pcvar_float(g_cvar_max_fall_speed);
    g_fAccceleration = get_pcvar_float(g_cvar_acceleration);
    g_fDeceleration = get_pcvar_float(g_cvar_deceleration);
    g_fVerticalAcceleration = get_pcvar_float(g_cvar_vertical_acceleration);
    g_fGravity = get_pcvar_float(g_cvar_gravity);
    g_fMinTurningAngle = get_pcvar_float(g_cvar_min_turning_angle);
    g_fMaxRotatingAngle = get_pcvar_float(g_cvar_max_rotating_angle);
    g_fMaxPitchAngle = get_pcvar_float(g_cvar_max_pitch_angle);
    g_fAngleRollMul = get_pcvar_float(g_cvar_angle_roll_mul);
    g_fAngleYawMul = get_pcvar_float(g_cvar_angle_yaw_mul);
    g_fAnglePitchMul = get_pcvar_float(g_cvar_angle_pitch_mul);
    g_fMaxPitchSpeed = get_pcvar_float(g_cvar_max_pitch_speed);
    g_fMaxRollSpeed = get_pcvar_float(g_cvar_max_roll_speed);
    g_fFireInterval = get_pcvar_float(g_cvar_fire_interval);
    g_fLaserDamage = get_pcvar_float(g_cvar_laser_damage);
    g_fCrashDamage = get_pcvar_float(g_cvar_crash_damage);
    g_fCrashTimeInterval = get_pcvar_float(g_cvar_crash_interval);
    g_fDefaultHp = get_pcvar_float(g_cvar_default_hp);
    g_fCameraDistance = get_pcvar_float(g_cvar_camera_distance);
}

create_airship(iId, const Float:vOrigin[3], const Float:vAngles[3], const Float:fHealth, const bCanShoot, const Float:fAttack, const bUseCamera, const bFreeMove, &retAirshipEnt = 0, &retCameraEnt = 0)
{
    cache_cvars();

    new iEnt = create_entity("info_target");
    entity_set_string(iEnt, EV_SZ_classname, AIRSHIP_CLASSNAME);
    entity_set_origin(iEnt, vOrigin);
    entity_set_vector(iEnt, EV_VEC_angles, vAngles);
    entity_set_model(iEnt, szAirshipModel);
    entity_set_edict(iEnt, EV_ENT_owner, iId);
    entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_FLY);
    entity_set_int(iEnt, EV_INT_solid, SOLID_BBOX);
    entity_set_int(iEnt, EV_INT_canshoot, bCanShoot);
    entity_set_int(iEnt, EV_INT_freemove, bFreeMove);
    entity_set_float(iEnt, EV_FL_takedamage, 1.0);
    entity_set_float(iEnt, EV_FL_health, fHealth <= 0.0 ? g_fDefaultHp : fHealth);
    entity_set_float(iEnt, EV_FL_dmg_save, fAttack <= 0.0 ? g_fLaserDamage : fAttack);
    
    entity_set_size(iEnt, g_vMins, g_vMaxs);
    entity_set_float(iEnt, EV_FL_nextthink, halflife_time() + AIRSHIP_THINK_INTERVAL);

    retAirshipEnt = iEnt;

    if (bUseCamera)
    {
        retCameraEnt = create_camera(iEnt, iId);
        entity_set_edict(iEnt, EV_ENT_cameraent, retCameraEnt);
        return;
    }

    retCameraEnt = 0;
    attach_view(iId, iEnt);
}

create_camera(iEnt, iOwner)
{
    new Float:vOrigin[3], Float:vAngles[3];
    entity_get_vector(iEnt, EV_VEC_origin, vOrigin);
    entity_get_vector(iEnt, EV_VEC_angles, vAngles);

    new iCameraEnt = create_entity("info_target");
    entity_set_string(iCameraEnt, EV_SZ_classname, CAMERA_CLASSNAME);
    
    // Initial position should be fCameraDistance units behind the airship
    new Float:vForwardVector[3], Float:vUpVector[3];
    angle_vector(vAngles, ANGLEVECTOR_FORWARD, vForwardVector);
    angle_vector(vAngles, ANGLEVECTOR_UP, vUpVector);
    xs_vec_mul_scalar(vForwardVector, g_fCameraDistance, vForwardVector);
    xs_vec_sub(vOrigin, vForwardVector, vOrigin);
    xs_vec_mul_scalar(vUpVector, g_fCameraDistance / 4.0, vUpVector);
    xs_vec_add(vOrigin, vUpVector, vOrigin);
    entity_set_origin(iCameraEnt, vOrigin);

    entity_set_vector(iCameraEnt, EV_VEC_angles, vAngles);
    entity_set_model(iCameraEnt, szAirshipModel);
    entity_set_int(iCameraEnt, EV_INT_movetype, MOVETYPE_FLY);
    entity_set_int(iCameraEnt, EV_INT_solid, SOLID_NOT);
    entity_set_int(iCameraEnt, EV_INT_rendermode, kRenderTransAlpha);
    entity_set_float(iCameraEnt, EV_FL_renderamt, 0.0);
    entity_set_float(iCameraEnt, EV_FL_nextthink, halflife_time() + CAMERA_THINK_INTERVAL);
    
    entity_set_edict(iCameraEnt, EV_ENT_cameraent, iEnt);
    
    attach_view(iOwner, iCameraEnt);
    
    return iCameraEnt;
}

public fw_AirshipThink(iEnt)
{
    static iId, iButtons;
    iId = entity_get_edict(iEnt, EV_ENT_owner);
    if (!is_user_alive(iId))
    {
        entity_set_int(iEnt, EV_INT_flags, entity_get_int(iEnt, EV_INT_flags) | FL_KILLME);
        return;
    }
    
    static Float:vOrigin[3], Float:vVelocity[3], Float:vAngles[3], Float:vAvelocity[3];
    static Float:vForwardVector[3], Float:vUpVector[3], Float:vRightVector[3], Float:vForwardVelocity[3], Float:vUpVelocity[3], Float:vRightVelocity[3];
    static Float:fSpeed, Float:fAbsSpeed, Float:fUpSpeed, Float:fRightSpeed, Float:fPrevSpeed;//, Float:fFallSpeed;
    static Float:fAbsRoll, Float:fSinRoll;
    static iFlipped, iBarrelRoll, Float:fCurrentTime, Float:fFireTime, Float:fBarrellRollTime, Float:fTimeDifference, iCanShoot, iFreeMove;

    entity_get_vector(iEnt, EV_VEC_angles, vAngles);
    entity_get_vector(iEnt, EV_VEC_origin, vOrigin);
    entity_get_vector(iEnt, EV_VEC_velocity, vVelocity);
    entity_get_vector(iEnt, EV_VEC_avelocity, vAvelocity);
    iBarrelRoll = entity_get_int(iEnt, EV_INT_barrelroll);
    fFireTime = entity_get_float(iEnt, EV_FL_firetime);
    iCanShoot = entity_get_int(iEnt, EV_INT_canshoot);
    iFreeMove = entity_get_int(iEnt, EV_INT_freemove);
    fBarrellRollTime = entity_get_float(iEnt, EV_FL_barrelrolltime);
    fCurrentTime = halflife_time();
    
    iButtons = entity_get_int(iId, EV_INT_button);
    
    // Obtain the unit vectors based on the airship orientation
    xs_anglevectors(vAngles, vForwardVector, vRightVector, vUpVector);
    
    /* Fire */
    if (iCanShoot && iButtons & IN_JUMP && fCurrentTime - fFireTime > g_fFireInterval)
    {
        static Float:vStartPoint[3], Float:vEndPoint[3];
        
        xs_vec_mul_scalar(vUpVector, -10.0, vStartPoint);
        xs_vec_copy(vOrigin, vStartPoint);
        
        xs_vec_mul_scalar(vForwardVector, 2000.0, vEndPoint);
        xs_vec_add(vEndPoint, vOrigin, vEndPoint);
        
        shoot_laser(iEnt, vOrigin, vEndPoint);
        
        entity_set_float(iEnt, EV_FL_firetime, fCurrentTime);
    }
    
    /* Fix roll angles */
    if (vAngles[XS_ROLL] > 180.0)
        vAngles[XS_ROLL] -= 360.0;
    
    if (vAngles[XS_ROLL] < -180.0)
        vAngles[XS_ROLL] += 360.0;
        
    fAbsRoll = floatabs(vAngles[XS_ROLL]);
    fSinRoll = floatsin(vAngles[XS_ROLL], degrees);
    iFlipped = (fAbsRoll > 89.9);
    
    /* Barrell Roll */
    if (!iBarrelRoll)
    {
        if (iButtons & IN_RELOAD)
        {
            fTimeDifference = fCurrentTime - fBarrellRollTime;
            if (fTimeDifference > 0.001 && fTimeDifference < 0.8)
            {
                // Do a barrell roll!
                emit_sound(iEnt, CHAN_VOICE, szBarrelRollSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
                iBarrelRoll = 1 + iFlipped;
                entity_set_int(iEnt, EV_INT_barrelroll, iBarrelRoll);
                entity_set_float(iEnt, EV_FL_takedamage, 0.0);
                
                vAvelocity[XS_ROLL] = 4.0 * g_fMaxRollSpeed;
            }
            
            entity_set_float(iEnt, EV_FL_barrelrolltime, fCurrentTime);
        }
    }
    else // Finishing a barrel roll
    {
        if ((iBarrelRoll == 2 && fAbsRoll < 5.0) || (iBarrelRoll == 1 && fAbsRoll > 175.0) || fCurrentTime - fBarrellRollTime > 1.5)
        {
            if (iFreeMove)
            {
                vAngles[XS_ROLL] = iBarrelRoll == 2 ? 0.0 : -179.9;
                vAvelocity[XS_ROLL] = 0.0;
            }
            
            iBarrelRoll = 0;
            entity_set_int(iEnt, EV_INT_barrelroll, 0);
            entity_set_float(iEnt, EV_FL_takedamage, 1.0);
        }
    }

    // Dot product of velocity vector and forward vector would return a positive value if entity is moving forward
    //static bIsMovingForward;
    //bIsMovingForward = (xs_vec_dot(vForwardVector, vVelocity) >= -0.5); // 0.5 bugfix
    
    /* Rotation */
    if (iButtons & IN_MOVERIGHT)
    {
        if (!iBarrelRoll)
        {
            if (!iFreeMove && ((!iFlipped && fAbsRoll >= g_fMaxRotatingAngle) || (iFlipped && fAbsRoll <= (180.0 - g_fMaxRotatingAngle))))
            {
                if (iFlipped)
                    vAngles[XS_ROLL] = vAngles[XS_ROLL] > 0.0 ? (180.0 - g_fMaxRotatingAngle) : (g_fMaxRotatingAngle - 180.0);
                else
                    vAngles[XS_ROLL] = vAngles[XS_ROLL] > 0.0 ? g_fMaxRotatingAngle : -g_fMaxRotatingAngle;

                vAvelocity[XS_ROLL] = 0.0;
            }
            else
            {
                vAvelocity[XS_ROLL] = floatmin(vAvelocity[XS_ROLL] + g_fAngleRollMul, g_fMaxRollSpeed);

                if (vAngles[XS_ROLL] < 0.0)
                    vAvelocity[XS_ROLL] = floatmax(vAvelocity[XS_ROLL], 3.0 * g_fMaxRollSpeed * (iFlipped ? fSinRoll : -fSinRoll));
            }
        }
    }
    else if (iButtons & IN_MOVELEFT)
    {
        if (!iBarrelRoll)
        {
            if (!iFreeMove && ((!iFlipped && fAbsRoll >= g_fMaxRotatingAngle) || (iFlipped && fAbsRoll <= (180.0 - g_fMaxRotatingAngle))))
            {
                if (iFlipped)
                    vAngles[XS_ROLL] = vAngles[XS_ROLL] > 0.0 ? (180.0 - g_fMaxRotatingAngle) : (g_fMaxRotatingAngle - 180.0);
                else
                    vAngles[XS_ROLL] = vAngles[XS_ROLL] > 0.0 ? g_fMaxRotatingAngle : -g_fMaxRotatingAngle;

                vAvelocity[XS_ROLL] = 0.0;
            }
            else
            {
                vAvelocity[XS_ROLL] = floatmax(vAvelocity[XS_ROLL] - g_fAngleRollMul, -g_fMaxRollSpeed);

                if (vAngles[XS_ROLL] > 0.0)
                    vAvelocity[XS_ROLL] = floatmin(vAvelocity[XS_ROLL], 3.0 * g_fMaxRollSpeed * (iFlipped ? fSinRoll : -fSinRoll));
            }
        }
    }
    else if (!iBarrelRoll)
    {
        if (!iFreeMove)
        {
            // If Roll angle is almost 0, lets fix it
            if (fAbsRoll < 1.0) // Bugfix: avoid rotating loop
            {
                vAngles[XS_ROLL] = 0.0;
                vAvelocity[XS_ROLL] = 0.0;
                fAbsRoll = 0.0;
            }
            else if (fAbsRoll > 179.0) // Bugfix: avoid rotating loop
            {
                vAngles[XS_ROLL] = 179.99;
                vAvelocity[XS_ROLL] = 0.0;
                fAbsRoll = 179.99;
            }
            else // If not, it should return back to 0, softly
            {
                vAvelocity[XS_ROLL] = 3.0 * g_fMaxRollSpeed * (iFlipped ? fSinRoll : -fSinRoll);
            }
        }
        else
        {
            // Return roll velocity back to 0
            if (floatabs(vAvelocity[XS_ROLL]) < 2.0)
                vAvelocity[XS_ROLL] = 0.0;
            else
                vAvelocity[XS_ROLL] /= 2.0;
        }
    }
    
    /* Move forward / back */
    fPrevSpeed = entity_get_float(iEnt, EV_FL_prevspeed);
    fSpeed = floatmin(xs_vec_len(vVelocity), fPrevSpeed);
    fAbsSpeed = floatabs(fSpeed);
    
    if (iButtons & IN_FORWARD)
        fSpeed = floatmin(g_fMaxSpeed, fSpeed + g_fAccceleration);
    else if (iButtons & IN_BACK)
        fSpeed = floatmax(-g_fMaxSpeed, fSpeed - g_fAccceleration);
    else
    {
        if (fSpeed > 0.0)
            fSpeed = floatmax(0.0, fSpeed - g_fDeceleration);
        else
            fSpeed = floatmin(0.0, fSpeed + g_fDeceleration);
    }
    
    /* Yaw velocity is calculated from airship rotation (roll) */
    if (iBarrelRoll)
    {
        fUpSpeed = 0.0;
        fRightSpeed = 0.0;
    }
    else
    {
        fUpSpeed = fSinRoll * (iFlipped ? g_fMaxRollSpeed : -g_fMaxRollSpeed);
        fRightSpeed = 2.0 * -fSinRoll;

        if ((iFlipped && (180.0 - fAbsRoll) > g_fMinTurningAngle) || (!iFlipped && fAbsRoll > g_fMinTurningAngle))
            vAvelocity[XS_YAW] = g_fAngleYawMul * -fSinRoll;
        else
        {
            if (floatabs(vAvelocity[XS_YAW]) < 2.0)
                vAvelocity[XS_YAW] = 0.0;
            else
                vAvelocity[XS_YAW] /= 2.0;
        }
    }
    
    /* Elevation or falling */
    if (iButtons & IN_USE)
    {
        // If airship is flipped, then actions of IN_DUCK and IN_USE should be swapped
        if (iFlipped)
        {
            if (vAngles[XS_PITCH] >= g_fMaxPitchAngle)
            {
                vAngles[XS_PITCH] = g_fMaxPitchAngle;
                vAvelocity[XS_PITCH] = 0.0;
            }
            else
                vAvelocity[XS_PITCH] = floatmin(vAvelocity[XS_PITCH] + g_fAnglePitchMul, g_fMaxPitchSpeed);
        }
        else
        {
            if (vAngles[XS_PITCH] <= -g_fMaxPitchAngle)
            {
                vAngles[XS_PITCH] = -g_fMaxPitchAngle;
                vAvelocity[XS_PITCH] = 0.0;
            }
            else
                vAvelocity[XS_PITCH] = floatmax(vAvelocity[XS_PITCH] - g_fAnglePitchMul, -g_fMaxPitchSpeed);
            
            if (fPrevSpeed < g_fMaxSpeed / 3.0)
                fUpSpeed = floatmin(fUpSpeed + g_fVerticalAcceleration, g_fMaxUpSpeed);
        }
    }
    else if (iButtons & IN_DUCK)
    {
        if (iFlipped)
        {
            if (vAngles[XS_PITCH] <= -g_fMaxPitchAngle)
            {
                vAngles[XS_PITCH] = -g_fMaxPitchAngle;
                vAvelocity[XS_PITCH] = 0.0;
            }
            else
                vAvelocity[XS_PITCH] = floatmax(vAvelocity[XS_PITCH] - g_fAnglePitchMul, -g_fMaxPitchSpeed);
            
            if (fPrevSpeed < g_fMaxSpeed / 3.0)
                fUpSpeed = floatmax(fUpSpeed - g_fVerticalAcceleration, -g_fMaxUpSpeed);
        }
        else
        {
            if (vAngles[XS_PITCH] >= g_fMaxPitchAngle)
            {
                vAngles[XS_PITCH] = g_fMaxPitchAngle;
                vAvelocity[XS_PITCH] = 0.0;
            }
            else
                vAvelocity[XS_PITCH] = floatmin(vAvelocity[XS_PITCH] + g_fAnglePitchMul, g_fMaxPitchSpeed);
        }
    }
    else
    {
        // Return pitch back to normal if not ascending/descending
        if (floatabs(vAngles[XS_PITCH]) < 0.5)
        {
            vAngles[XS_PITCH] = 0.0;
            vAvelocity[XS_PITCH] = 0.0;
        }
        else
            vAvelocity[XS_PITCH] = -vAngles[XS_PITCH] * 2.0;
    }
    
    xs_vec_mul_scalar(vForwardVector, fSpeed, vForwardVelocity);
    xs_vec_mul_scalar(vRightVector, fRightSpeed, vRightVelocity);
    xs_vec_mul_scalar(vUpVector, fUpSpeed, vUpVelocity);
    
    xs_vec_add(vForwardVelocity, vUpVelocity, vVelocity);
    xs_vec_add(vVelocity, vRightVelocity, vVelocity);
    //vVelocity[2] += fFallSpeed;
    
    // Gravity should not affect the airship if FreeMove mode is enabled
    if (!iFreeMove && vVelocity[2] > -g_fMaxFallSpeed && fAbsSpeed < g_fMaxSpeed)
        vVelocity[2] -= g_fGravity * (g_fMaxSpeed - fAbsSpeed) / g_fMaxSpeed;
        
    entity_set_vector(iEnt, EV_VEC_avelocity, vAvelocity);
    entity_set_vector(iEnt, EV_VEC_velocity, vVelocity);
    entity_set_float(iEnt, EV_FL_prevspeed, fSpeed);
    entity_set_vector(iEnt, EV_VEC_angles, vAngles);
    
    entity_set_float(iEnt, EV_FL_nextthink, fCurrentTime + AIRSHIP_THINK_INTERVAL);
}

public fw_CameraThink(iEnt)
{
    static iAirshipEnt;

    iAirshipEnt = entity_get_edict(iEnt, EV_ENT_cameraent);
    if (!is_valid_ent(iAirshipEnt))
    {
        entity_set_int(iEnt, EV_INT_flags, entity_get_int(iEnt, EV_INT_flags) | FL_KILLME);
        return;
    }

    static Float:vAirshipOrigin[3], Float:vAirshipAngles[3];
    static Float:vNextOrigin[3], Float:vCameraOrigin[3], Float:vCameraAngles[3], Float:vNextAngles[3];
    static Float:vAirshipVelocity[3], Float:vCameraVelocity[3], Float:vNextVelocity[3], Float:vForwardVector[3], Float:vUpVector[3], Float:vReturn[3];
    static Float:fAirshipSpeed, Float:fDistance, Float:vDistance[3], Float:fSpeedConst;

    fSpeedConst = g_fMaxSpeed / g_fCameraDistance;

    entity_get_vector(iAirshipEnt, EV_VEC_origin, vAirshipOrigin);
    entity_get_vector(iAirshipEnt, EV_VEC_angles, vAirshipAngles);
    entity_get_vector(iAirshipEnt, EV_VEC_velocity, vAirshipVelocity);
    entity_get_vector(iEnt, EV_VEC_origin, vCameraOrigin);
    entity_get_vector(iEnt, EV_VEC_angles, vCameraAngles);
    entity_get_vector(iEnt, EV_VEC_velocity, vCameraVelocity);
    fAirshipSpeed = xs_vec_len(vAirshipVelocity);

    angle_vector(vAirshipAngles, ANGLEVECTOR_FORWARD, vForwardVector);
    angle_vector(vAirshipAngles, ANGLEVECTOR_UP, vUpVector);
    xs_vec_mul_scalar(vForwardVector, g_fCameraDistance * (g_fMaxSpeed - fAirshipSpeed) / g_fMaxSpeed, vNextOrigin);
    xs_vec_sub(vAirshipOrigin, vNextOrigin, vNextOrigin);
    xs_vec_mul_scalar(vUpVector, g_fCameraDistance / 4.0, vUpVector);
    xs_vec_add(vNextOrigin, vUpVector, vNextOrigin);

    trace_line(iAirshipEnt, vAirshipOrigin, vNextOrigin, vReturn);
    //xs_vec_mul_scalar(vForwardVector, 5.0, vNextOrigin); // Unstuck fix
    xs_vec_add(vReturn, vForwardVector, vNextOrigin);

    // Check if stuck
    xs_vec_sub(vAirshipOrigin, vCameraOrigin, vDistance);
    fDistance = xs_vec_len(vDistance);
    if (fDistance > fSpeedConst * g_fCameraDistance)
    {
        // Unstuck
        entity_set_vector(iEnt, EV_VEC_origin, vNextOrigin);
        entity_set_vector(iEnt, EV_VEC_angles, vAirshipAngles);
        entity_set_vector(iEnt, EV_VEC_avelocity, Float:{0.0, 0.0, 0.0});
    }
    else
    {
        xs_vec_sub(vNextOrigin, vCameraOrigin, vNextVelocity);
        xs_vec_mul_scalar(vNextVelocity, fSpeedConst, vNextVelocity);

        entity_set_vector(iEnt, EV_VEC_velocity, vNextVelocity);

        vec_to_angle(vDistance, vNextAngles);
        vNextAngles[XS_ROLL] = vAirshipAngles[XS_ROLL];
        xs_vec_sub(vNextAngles, vCameraAngles, vNextAngles);
        vNextAngles[XS_YAW] = fit_angle(vNextAngles[XS_YAW]);
        vNextAngles[XS_ROLL] = fit_angle(vNextAngles[XS_ROLL]) / 2.0;
        xs_vec_mul_scalar(vNextAngles, 1.5 * fSpeedConst * fDistance / g_fCameraDistance, vNextAngles);

        entity_set_vector(iEnt, EV_VEC_avelocity, vNextAngles);
    }

    entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + CAMERA_THINK_INTERVAL);
}

public fw_AirshipTouch(iTouched, iEnt)
{
    static Float:fLastTouchTime, Float:fCurrentTime;
    fCurrentTime = halflife_time();
    fLastTouchTime = entity_get_float(iEnt, EV_FL_lasttouchtime);

    if (fCurrentTime - fLastTouchTime < g_fCrashTimeInterval)
        return;
    
    static Float:vVelocity[3], Float:fSpeed, Float:fDamage;
    entity_get_vector(iEnt, EV_VEC_velocity, vVelocity);
    fSpeed = xs_vec_len(vVelocity);

    if (fSpeed < g_fMaxSpeed / 2.0)
        return;

    entity_set_float(iEnt, EV_FL_lasttouchtime, fCurrentTime);
    fDamage = g_fCrashDamage * fSpeed / g_fMaxSpeed;

    new iRet;
    ExecuteForward(g_fwCrashPre, iRet, iEnt, iTouched, fDamage);

    if (iRet >= PLUGIN_HANDLED)
        return;

    new iTouchedOwner;
    if (iTouched)
    {
        new szClassname[sizeof(AIRSHIP_CLASSNAME)];
        entity_get_string(iTouched, EV_SZ_classname, szClassname, charsmax(szClassname));
        if (equal(szClassname, AIRSHIP_CLASSNAME))
            iTouchedOwner = entity_get_edict(iTouched, EV_ENT_owner);
        else
            iTouchedOwner = iTouched;
    }

    ExecuteHamB(Ham_TakeDamage, iEnt, iTouched, iTouchedOwner, fDamage, DMG_FALL);
    ExecuteForward(g_fwCrashPost, iRet, iEnt, iTouched, fDamage);	
}

public fw_AirshipKilled(iEnt, iKiller, iGib)
{
    static szClassname[sizeof(AIRSHIP_CLASSNAME)];
    entity_get_string(iEnt, EV_SZ_classname, szClassname, charsmax(szClassname));

    if (!equal(szClassname, AIRSHIP_CLASSNAME))
        return HAM_IGNORED;
    
    static iRet, iOwner, iKillerOwner;
    iOwner = entity_get_edict(iEnt, EV_ENT_owner);

    if (iKiller)
    {
        entity_get_string(iKiller, EV_SZ_classname, szClassname, charsmax(szClassname));
        if (equal(szClassname, AIRSHIP_CLASSNAME))
            iKillerOwner = entity_get_edict(iKiller, EV_ENT_owner);
        else
            iKillerOwner = 0;
    }
    else
        iKillerOwner = 0;

    ExecuteForward(g_fwKilledPre, iRet, iEnt, iOwner, iKiller, iKillerOwner);

    if (iRet >= PLUGIN_HANDLED)
        return HAM_SUPERCEDE;

    ExecuteForward(g_fwKilledPost, iRet, iEnt, iOwner, iKiller, iKillerOwner);
    
    return HAM_IGNORED;
}

shoot_laser(iEnt, Float:vStartPoint[3], Float:vEndPoint[3])
{
    static Float:vReturn[3];
    trace_line(iEnt, vStartPoint, vEndPoint, vReturn);
    static iHitEnt;
    iHitEnt = traceresult(TR_Hit);

    if (iHitEnt && is_valid_ent(iHitEnt))
    {
        static szClassname[sizeof(AIRSHIP_CLASSNAME)];
        entity_get_string(iHitEnt, EV_SZ_classname, szClassname, charsmax(szClassname));

        if (equal(szClassname, AIRSHIP_CLASSNAME))
        {
            static iRet, Float:fDamage;
            fDamage = entity_get_float(iEnt, EV_FL_dmg_save);

            ExecuteForward(g_fwLaserHitPre, iRet, iHitEnt, iEnt, fDamage);

            if (iRet == PLUGIN_CONTINUE)
            {
                ExecuteHamB(Ham_TakeDamage, iHitEnt, iEnt, entity_get_edict(iEnt, EV_ENT_owner), fDamage, DMG_ENERGYBEAM);
                ExecuteForward(g_fwLaserHitPost, iRet, iHitEnt, iEnt, fDamage);
            }
        }
    }

    static ivEndPoint[3];
    FVecIVec(vReturn, ivEndPoint);
    
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMENTPOINT);
    write_short(iEnt);
    write_coord(ivEndPoint[0]); // End of the beam
    write_coord(ivEndPoint[1]);
    write_coord(ivEndPoint[2]);
    write_short(g_iSprLaser); // sprite index
    write_byte(0); // start frame
    write_byte(0); // FPS in 0.1
    write_byte(2); // Lifetime in 0.1
    write_byte(25); // Width 0.1
    write_byte(0); // distortion in 0.1
    write_byte(0); // Red (R)
    write_byte(240); // Green (G)
    write_byte(200); // Blue (B)
    write_byte(200); // brightness
    write_byte(0); // scroll speed in 0.1
    message_end();
    
    emit_sound(iEnt, CHAN_BODY, szFireSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

stock vec_to_angle(Float:in[3], Float:out[3])
{
    out[0] = -floatatan(in[2] * xs_rsqrt(in[0]*in[0] + in[1]*in[1]), degrees);
    out[1] = fit_angle(floatatan2(in[1], in[0], degrees));
    out[2] = 0.0;
}

stock Float:fit_angle(Float:fIn)
{
    static Float:fAngle;
    fAngle = fIn;

    while (fAngle > 180.0)
        fAngle -= 360.0;
    
    while (fAngle < -180.0)
        fAngle += 360.0;
    
    return fAngle;
}