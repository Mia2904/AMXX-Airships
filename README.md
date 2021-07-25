# Airships Engine - AMXX

This set of plugins will make it possible to spawn airships. They can be controlled with basic controls, shoot laser beams and even do barrel rolls!

The core (airships_core.amxx) will manage the physics. It does nothing by itself! Instead, provides an API for using the airships in any mod.

### Controls
* W, A, S, D for moving forward / sidewards / backwards.
* +Use (E) can be used to elevate, and +Duck (CTRL) for descending.
* +Jump (Space) shoots a laser beam.
* +Reload (R) twice for a barrel roll!

### Provided plugins
* airships_core.amxx - Physics box. Also handles damage and camera.
* airships_explosion.amxx - Explosion animation add-on. Will animate an explosion when an airship is killed.
* airships_test.amxx - For testing purposes: type 'airship' in chat to spawn an airship.
* cs_hide_hud.amxx - For using with Counter-Strike. Hides the unnecessary huds (radar, health and crosshair).

### Installation
* Place airships.inc in your /include folder, then compile each plugin locally.
* It has been tested with AMXX 1.8.2 and 1.9.0.
* It doesn't require any modules other than the default ones. It doesn't even require ReHLDS, but it is suggested to use it.

### API
* See airships.inc for information.

### Cvar list (see airships_core.sma for default values)
* Max speed an airship should be able to move forward 
as_max_speed

* Max speed an airship should be able to move upwards
as_max_up_speed

* Max speed an airship should be able to fall
as_max_fall_speed

* Acceleration value for moving forward / backwards
as_acceleration

* Deceleration speed when not pressing the gas buttons
as_deceleration

* Vertical acceleration (when pressing +DUCK / +USE)
as_up_acceleration

* Absolute gravity of airships
as_gravity

* Minimum angle of roll required to start turning sidewards
as_min_turning_angle

* Maximum angle an airship is permitted to roll if not in freemode
as_max_rotating_angle

* Maximum vertical angle (pitch) an airship is permitted to rotate (+DUCK / +USE)
as_max_pitch_angle

* Kind of an angular acceleration, for roll. Used when turning (IN_MOVELEFT / IN_MOVERIGHT)
as_angle_roll_mul

* Kind of an angular acceleration, for yaw. Used when turning (IN_MOVELEFT / IN_MOVERIGHT).
* The final acceleration is calculated based on this value and the current roll angle.
as_angle_yaw_mul

* Kind of an angular acceleration, for pitch. Used when elevating/descending (+DUCK / +USE)
as_angle_pitch_mul

* Maximum angular speed an airship can rotate (pitch, when +DUCK / +USE)
as_max_pitch_speed

* Maximum angular speed an airship can rotate (roll, when IN_MOVELEFT / IN_MOVERIGHT)
as_max_roll_speed

* Time interval in seconds an airship is allowed to fire
as_fire_interval

* Default damage a laser shoot inflicts to an airship. Can be overrided with the parameter fAttack in spawn native
as_default_attack

* Maximum damage a crash inflicts to an airship (a colision is considered a crash if speed is greater than half the max speed)
as_crash_damage

* Time interval (in seconds) between crashes (to prevent the same crash to inflict damage more than once)
as_crash_interval

* Default airship HP. Can be overrided with the parameter fHealth in the creation native
as_default_hp

* Distance (in game units) the camera should stay behind their airship. It may move a bit from that distance depending on the speed of the airship
as_camera_min_distance

### Support
* AM-ES: https://amxmodx-es.com/member.php?action=profile&uid=402 (Send a PM).
* Or submit an issue in this repository.