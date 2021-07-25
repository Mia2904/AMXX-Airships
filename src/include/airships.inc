#if defined _airships_included
	#endinput
#endif
#define _airships_included

new const AIRSHIP_CLASSNAME[] = "AirShip"
new const CAMERA_CLASSNAME[] = "ASCamera"
#pragma unused AIRSHIP_CLASSNAME
#pragma unused CAMERA_CLASSNAME

#if !defined _engine_const_included
	#include <engine_const>
#endif

/**
 * Constants for using with entity_[get/set] [engine]
 *
 * @note You should know what you are doing if messing up with these.
 */
const EV_ENT_cameraent = EV_ENT_euser1;
const EV_FL_prevspeed = EV_FL_fuser1;
const EV_FL_firetime = EV_FL_fuser2;
const EV_FL_barrelrolltime = EV_FL_fuser3;
const EV_FL_lasttouchtime = EV_FL_fuser4;
const EV_INT_barrelroll = EV_INT_iuser1;
const EV_INT_canshoot = EV_INT_iuser2;
const EV_INT_freemove = EV_INT_iuser3;

/**
 * Spawns an airship.
 *
 * @note Player view will be attached to the airship, or the camera if bUseCamera is true.
 *
 * @param iOwner         Index of the owner (must be a connected player).
 * @param vOrigin        Coordinates where the airship should spawn.
 * @param vAngles        Angles to orientate the airship on spawn.
 * @param fHealth        Base health. Use 0.0 for default health (see cvars).
 * @param bCanShoot      If true, the airship will be able to shoot a laser.
 * @param fAttack        Base attack (for laser), only applies if bCanShoot is true. Use 0.0 for default attack (see cvars).
 * @param bUseCamera     If true, a camera entity will spawn. The camera will follow the airship.
 * @param bFreeMove      If true, the airship will not orientate itself straight, instead it will rotate freely.
 * @param retAirshipEnt  Cell to store the airship entity index to.
 * @param retCameraEnt   Cell to store the camera entity index to.
 *
 * @return               1
 */
native as_spawn(iOwner, const Float:vOrigin[3], const Float:vAngles[3], const Float:fHealth = 0.0, const bCanShoot = true, const Float:fAttack = 0.0, const bUseCamera = false, const bFreeMove = false, &retAirshipEnt = 0, &retCameraEnt = 0);

/**
 * Sets the airship camera type for a player.
 *
 * @note Player must own an airship for this native to work.
 *
 * @param iId      Player index.
 * @param bCamera  Set to true for using a 3rd view camera. Set to false for default view.
 *
 * @return         Entity index of the camera, if bCamera is true. 0 otherwise.
 */
native as_set_camera(iId, bCamera);

/**
 * Returns the airship id of a player (if any).
 *
 * @param iId       Player index.
 *
 * @return          Entity id, or 0 if there is none.
 */
native as_get_user_airship(iId);

/**
 * Gives an already existing airship to a player.
 *
 * @note If this player already had an airship, its index will be lost! Be careful to store it before using this native.
 * @note The view of the player will be attached to the airship, or the camera if this airship has one.
 * @note You may need to attach the view of the previous owner of this arship to something else.
 *
 * @param iId       Player index.
 * @param iEnt      Airship entity index.
 *
 * @return          1 on success, 0 on error.
 */
native as_set_user_airship(iId, iEnt);

/**
 * Called before a laser impact.
 *
 * @note Currently, damage can't be modified in this forward. You can use fDamage as a reference to calculate any modifications and give the victim some HP
 *
 * @param iEnt       Airship (victim) entity index.
 * @param iAttacker  Airship (attacker) entity index.
 * @param fDamage    Damage that is going to be inflicted.
 *
 * @return           PLUGIN_CONTINUE to ignore, PLUGIN_HANDLED to block.
 */
forward as_LaserHit_Pre(iEnt, iAttacker, Float:fDamage);

/**
 * Called after a succesful laser impact.
 *
 * @note Damage has been inflicted already at this point.
 *
 * @param iEnt       Airship (victim) entity index.
 * @param iAttacker  Airship (attacker) entity index.
 * @param fDamage    Inflicted damage.
 *
 * @noreturn
 */
forward as_LaserHit_Post(iEnt, iAttacker, Float:fDamage);

/**
 * Called before an airship crashes.
 *
 * @note This is not a touch! A crash happens if the airship colides with a solid entity at a speed greater than half the maximum speed. It can happen once every crash interval (see cvars).
 *
 * @param iEnt       Airship entity index.
 * @param iOther     The other entity index. It could be 0 (worldspawn), another airship, or any other entity.
 * @param fDamage    Inflicted damage (it depends on speed).
 *
 * @return           PLUGIN_CONTINUE to ignore, PLUGIN_HANDLED to block.
 */
forward as_Crash_Pre(iEnt, iOther, Float:fDamage);

/**
 * Called after an airship has crashed.
 *
 * @note Damage has been already inflicted at this point.
 *
 * @param iEnt       Airship entity index.
 * @param iOther     The other entity index. It could be 0 (worldspawn), another airship, or any other entity.
 * @param fDamage    Inflicted damage (it depends on speed).
 *
 * @noreturn
 */
forward as_Crash_Post(iEnt, iOther, Float:fDamage);

/**
 * Called before an airship dies.
 *
 * @note If preventing the airship from dying, make sure to give it some HP before returning PLUGIN_HANDLED.
 *
 * @param iEnt           Airship (victim) entity index.
 * @param iPlayer        Victim owner (player) entity index.
 * @param iKillerEnt     Killer entity index, if applicable. It isn't necessarily an airship, could be another entity if died from a collision.
 * @param iKillerPlayer  If iKilledEnt is an airship, this will be the index of the owner (player), or 0 otherwise.
 *
 * @return               PLUGIN_CONTINUE to ignore, PLUGIN_HANDLED to block.
 */
forward as_Killed_Pre(iEnt, iPlayer, iKillerEnt, iKillerPlayer);

/**
 * Called after a successful kill attempt. The airship entity still exists in the current frame.
 *
 * @note The camera entity will be removed in it's next think.
 *
 * @param iEnt           Airship (victim) entity index.
 * @param iPlayer        Victim owner (player) entity index.
 * @param iKillerEnt     Killer entity index, if applicable. It isn't necessarily an airship, could be another entity if died from a collision.
 * @param iKillerPlayer  If iKilledEnt is an airship, this will be the index of the owner (player), or 0 otherwise.
 *
 * @noreturn
 */
forward as_Killed_Post(iEnt, iPlayer, iKillerEnt, iKillerPlayer);