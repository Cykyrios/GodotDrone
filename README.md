# Godot Drone
This is a drone simulation made in Godot. You can fly around as you want or try racing along some MultiGP tracks I recreated.

## Quad customization
You can tweak the camera angle as well as the weight of both the drone itself and the battery. Want to do some freestyle? 700g is about right for a quad equipped with an action camera. Fancy a race? 300g is probably closer to actual racers.

You can also adjust the rates and expo of the pitch, roll and yaw axes. PIDs are not customizable at this time, I would need to either change my flight controller implementation or try to get BetaFlight in, but that would probably require quite a bit of work.

## Controls
A controller or radio transmitter is necessary to play! Or anything that your computer recognizes as having 4 axes, really. You can rebind controls in the options and auto-calibrate the 4 main axes. You can also use other axes to trigger actions, similar to what BetaFlight does.

You can consult the Help screen in game for some drone basics and keyboard shortcuts. Do not forget to bind a button or axis to either Arm or Toggle Arm, or you won't be able to fly!


## Graphics
The FPV camera has an optional fisheye mode, which feels more realistic than the standard game camera, but is also more expensive on your GPU. A cheaper version is available at the cost of visual quality.

You will notice the only level is rather bland, I hope to change that at some point.

## Godot 4
I started this project on Godot 3 a few years back. Now that Godot 4 is around the corner (beta 1 at the time of this writing), I am converting the project and will only continue working on Godot 4.x. This will happen on the godot4 branch until a stable version is out. There are some unresolved issues, though:
* The fisheye camera does currenty does not work, as viewports have some unresolved issues
* Control bindings are broken
* Some HUD elements are broken
* Audio cuts a few seconds after arming the drone
* Probably more issues

## Development
I started this project as a hobby, and am not currently looking for pull requests - but do feel free to open issues and leave feedback. Also, the codebase is probably horrible and I am planning to refactor most of it while porting the project to Godot 4.
