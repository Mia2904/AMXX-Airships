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

### Cvar list <default values>
* Max speed an airship should be able to move forward

  __as_max_speed__ 700.0

* Max speed an airship should be able to move upwards

  __as_max_up_speed__ 200.0

* Max speed an airship should be able to fall

  __as_max_fall_speed__ 150.0

* Acceleration value for moving forward / backwards

  __as_acceleration__ 70.0

* Deceleration speed when not pressing the gas buttons

  __as_deceleration__ 30.0

* Vertical acceleration (when pressing +DUCK / +USE)

  __as_up_acceleration__ 15.0

* Absolute gravity of airships

  __as_gravity__ 20.0

* Minimum angle of roll required to start turning sidewards

  __as_min_turning_angle__ 0.0

* Maximum angle an airship is permitted to roll if not in freemode

  __as_max_rotating_angle__ 50.0

* Maximum vertical angle (pitch) an airship is permitted to rotate (+DUCK / +USE)

  __as_max_pitch_angle__ 50.0

* Kind of an angular acceleration, for roll. Used when turning (IN_MOVELEFT / IN_MOVERIGHT)

  __as_angle_roll_mul__ 15.0

* Kind of an angular acceleration, for yaw. Used when turning (IN_MOVELEFT / IN_MOVERIGHT).

  The final acceleration is calculated based on this value and the current roll angle.

  __as_angle_yaw_mul__ 80.0

* Kind of an angular acceleration, for pitch. Used when elevating/descending (+DUCK / +USE)

  __as_angle_pitch_mul__ 10.0

* Maximum angular speed an airship can rotate (pitch, when +DUCK / +USE)

  __as_max_pitch_speed__ 50.0

* Maximum angular speed an airship can rotate (roll, when IN_MOVELEFT / IN_MOVERIGHT)

  __as_max_roll_speed__ 30.0

* Time interval in seconds an airship is allowed to fire

  __as_fire_interval__ 0.4

* Default damage a laser shoot inflicts to an airship. Can be overrided with the parameter fAttack in spawn native

  __as_default_attack__ 100.0

* Maximum damage a crash inflicts to an airship (a colision is considered a crash if speed is greater than half the max speed)

  __as_crash_damage__ 200.0

* Time interval (in seconds) between crashes (to prevent the same crash to inflict damage more than once)

  __as_crash_interval__ 4.0

* Default airship HP. Can be overrided with the parameter fHealth in the creation native

  __as_default_hp__ 500.0

* Distance (in game units) the camera should stay behind their airship. It may move a bit from that distance depending on the speed of the airship

  __as_camera_min_distance__ 400.0

### Support
* AM-ES: https://amxmodx-es.com/member.php?action=profile&uid=402 (Send a PM).
* Or submit an issue in this repository.