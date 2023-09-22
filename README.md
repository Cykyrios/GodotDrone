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
I started this project on Godot 3 a few years back. Now that Godot 4 is out and I have ported the game to it, I am in the process of refactoring my admittedly poor code. I definitely wouldn't call this version "stable" by any mean, but it is now more or less on par with the Godot 3 version.

## Development
I started this project as a hobby, and am not currently looking for pull requests - but do feel free to open issues and leave feedback. Also, the codebase is probably horrible and I am in the process of refactoring most of it after porting the project to Godot 4.
