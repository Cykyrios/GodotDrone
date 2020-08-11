extends WorldEnvironment


enum Axis {THROTTLE, YAW, PITCH, ROLL}
enum Mode {MODE_1, MODE_2, MODE_3, MODE_4}


var mode: int = Mode.MODE_2

onready var skeleton := $RadioTransmitter/Armature/Skeleton
var accept_input := true


func _input(event) -> void:
	if event is InputEventJoypadMotion and accept_input:
		var stick := -1
		var axis := Vector3.ZERO
		var value := 0.0
		if event.is_action("throttle_up") or event.is_action("throttle_down"):
			stick = get_stick(Axis.THROTTLE)
			axis = Vector3.RIGHT
			value = event.get_action_strength("throttle_down") - event.get_action_strength("throttle_up")
		elif event.is_action("yaw_left") or event.is_action("yaw_right"):
			stick = get_stick(Axis.YAW)
			axis = Vector3.FORWARD
			value = event.get_action_strength("yaw_right") - event.get_action_strength("yaw_left")
		elif event.is_action("pitch_up") or event.is_action("pitch_down"):
			stick = get_stick(Axis.PITCH)
			axis = Vector3.RIGHT
			value = event.get_action_strength("pitch_up") - event.get_action_strength("pitch_down")
		elif event.is_action("roll_left") or event.is_action("roll_right"):
			stick = get_stick(Axis.ROLL)
			axis = Vector3.FORWARD
			value = event.get_action_strength("roll_right") - event.get_action_strength("roll_left")
		if stick > -1:
			var angle := deg2rad(27 * value)
			skeleton.set_bone_pose(stick, Transform.IDENTITY.rotated(axis, angle))


func get_stick(axis: int) -> int:
	match mode:
		Mode.MODE_1:
			match axis:
				Axis.THROTTLE:
					return 1
				Axis.YAW:
					return 4
				Axis.PITCH:
					return 3
				Axis.ROLL:
					return 2
		Mode.MODE_2:
			match axis:
				Axis.THROTTLE:
					return 3
				Axis.YAW:
					return 4
				Axis.PITCH:
					return 1
				Axis.ROLL:
					return 2
		Mode.MODE_3:
			match axis:
				Axis.THROTTLE:
					return 1
				Axis.YAW:
					return 2
				Axis.PITCH:
					return 3
				Axis.ROLL:
					return 4
		Mode.MODE_4:
			match axis:
				Axis.THROTTLE:
					return 3
				Axis.YAW:
					return 2
				Axis.PITCH:
					return 1
				Axis.ROLL:
					return 4
	return -1
