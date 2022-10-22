extends WorldEnvironment


enum Stick {RIGHT_VERTICAL = 1, RIGHT_HORIZONTAL, LEFT_VERTICAL, LEFT_HORIZONTAL}
enum Axis {THROTTLE, YAW, PITCH, ROLL}
enum Mode {MODE_1, MODE_2, MODE_3, MODE_4}


const MAX_ANGLE := 27.0


var mode: int = Mode.MODE_2

@onready var skeleton := $RadioTransmitter/Armature/Skeleton3D as Skeleton3D
var accept_input := true


func _unhandled_input(event) -> void:
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
			var angle := get_stick_angle(value)
			skeleton.set_bone_global_pose_override(stick,
					skeleton.get_bone_global_pose(skeleton.get_bone_parent(stick)) \
					* skeleton.get_bone_rest(stick) \
					* Transform3D.IDENTITY.rotated(axis, angle), 1.0, true)
			skeleton.force_update_bone_child_transform(stick)


func get_stick_angle(value: float) -> float:
	return deg_to_rad(MAX_ANGLE * value)


func get_stick(axis: int) -> int:
	match mode:
		Mode.MODE_1:
			match axis:
				Axis.THROTTLE:
					return Stick.RIGHT_VERTICAL
				Axis.YAW:
					return Stick.LEFT_HORIZONTAL
				Axis.PITCH:
					return Stick.LEFT_VERTICAL
				Axis.ROLL:
					return Stick.RIGHT_HORIZONTAL
		Mode.MODE_2:
			match axis:
				Axis.THROTTLE:
					return Stick.LEFT_VERTICAL
				Axis.YAW:
					return Stick.LEFT_HORIZONTAL
				Axis.PITCH:
					return Stick.RIGHT_VERTICAL
				Axis.ROLL:
					return Stick.RIGHT_HORIZONTAL
		Mode.MODE_3:
			match axis:
				Axis.THROTTLE:
					return Stick.RIGHT_VERTICAL
				Axis.YAW:
					return Stick.RIGHT_HORIZONTAL
				Axis.PITCH:
					return Stick.LEFT_VERTICAL
				Axis.ROLL:
					return Stick.LEFT_HORIZONTAL
		Mode.MODE_4:
			match axis:
				Axis.THROTTLE:
					return Stick.LEFT_VERTICAL
				Axis.YAW:
					return Stick.RIGHT_HORIZONTAL
				Axis.PITCH:
					return Stick.RIGHT_VERTICAL
				Axis.ROLL:
					return Stick.LEFT_HORIZONTAL
	return -1


func set_left_stick_horizontal(value: float) -> void:
	var angle := get_stick_angle(value)
	skeleton.set_bone_pose(Stick.LEFT_HORIZONTAL, Transform3D.IDENTITY.rotated(Vector3.FORWARD, angle))


func set_left_stick_vertical(value: float) -> void:
	var angle := get_stick_angle(value)
	skeleton.set_bone_pose(Stick.LEFT_VERTICAL, Transform3D.IDENTITY.rotated(Vector3.RIGHT, angle))


func set_right_stick_horizontal(value: float) -> void:
	var angle := get_stick_angle(value)
	skeleton.set_bone_pose(Stick.RIGHT_HORIZONTAL, Transform3D.IDENTITY.rotated(Vector3.FORWARD, angle))


func set_right_stick_vertical(value: float) -> void:
	var angle := get_stick_angle(value)
	skeleton.set_bone_pose(Stick.RIGHT_VERTICAL, Transform3D.IDENTITY.rotated(Vector3.RIGHT, angle))


func set_throttle_stick(value: float) -> void:
	if mode == Mode.MODE_1 or mode == Mode.MODE_3:
		set_right_stick_vertical(value)
	else:
		set_left_stick_vertical(value)


func set_yaw_stick(value: float) -> void:
	if mode == Mode.MODE_1 or mode == Mode.MODE_2:
		set_left_stick_horizontal(value)
	else:
		set_right_stick_horizontal(value)


func set_pitch_stick(value: float) -> void:
	if mode == Mode.MODE_1 or mode == Mode.MODE_3:
		set_left_stick_vertical(value)
	else:
		set_right_stick_vertical(value)


func set_roll_stick(value: float) -> void:
	if mode == Mode.MODE_1 or mode == Mode.MODE_2:
		set_right_stick_horizontal(value)
	else:
		set_left_stick_horizontal(value)


func play_animation(calibration_step: int) -> void:
	var tween := get_tree().create_tween()
#	tween.set_loops(0)
#	match calibration_step:
#		0:
#			tween.repeat = false
#			tween.interpolate_method(self, "set_left_stick_horizontal", 0, -1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#			tween.interpolate_method(self, "set_left_stick_vertical", 0, -1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#			tween.interpolate_method(self, "set_right_stick_horizontal", 0, 1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#			tween.interpolate_method(self, "set_right_stick_vertical", 0, -1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#			var _discard = tween.tween_all_completed.connect(loop_stick_animation)
#		1:
#			tween.interpolate_method(self, "set_left_stick_horizontal", 0, 0,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#			tween.interpolate_method(self, "set_left_stick_vertical", 0, 0,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#			tween.interpolate_method(self, "set_right_stick_horizontal", 0, 0,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#			tween.interpolate_method(self, "set_right_stick_vertical", 0, 0,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#		2:
#			tween.interpolate_method(self, "set_throttle_stick", 0, -1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#		3:
#			tween.interpolate_method(self, "set_throttle_stick", -1, 1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#		4:
#			tween.interpolate_method(self, "set_throttle_stick", 1, 0,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#		5:
#			set_throttle_stick(0)
#			tween.interpolate_method(self, "set_yaw_stick", 0, -1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#		6:
#			tween.interpolate_method(self, "set_yaw_stick", -1, 1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#		7:
#			tween.interpolate_method(self, "set_yaw_stick", 1, 0,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#		8:
#			set_yaw_stick(0)
#			tween.interpolate_method(self, "set_pitch_stick", 0, -1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#		9:
#			tween.interpolate_method(self, "set_pitch_stick", -1, 1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#		10:
#			tween.interpolate_method(self, "set_pitch_stick", 1, 0,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#		11:
#			set_pitch_stick(0)
#			tween.interpolate_method(self, "set_roll_stick", 0, -1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#		12:
#			tween.interpolate_method(self, "set_roll_stick", -1, 1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#		13:
#			tween.interpolate_method(self, "set_roll_stick", 1, 0,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#		_:
#			set_roll_stick(0)
#	tween.start()


func loop_stick_animation() -> void:
#	tween_loop += 1
#	match tween_loop:
#		1:
#			tween.interpolate_method(self, "set_left_stick_horizontal", -1, 1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#			tween.interpolate_method(self, "set_right_stick_horizontal", 1, -1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#		2:
#			tween.interpolate_method(self, "set_left_stick_vertical", -1, 1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#			tween.interpolate_method(self, "set_right_stick_vertical", -1, 1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#		3:
#			tween.interpolate_method(self, "set_left_stick_horizontal", 1, -1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#			tween.interpolate_method(self, "set_right_stick_horizontal", -1, 1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#		4:
#			tween.interpolate_method(self, "set_left_stick_vertical", 1, -1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#			tween.interpolate_method(self, "set_right_stick_vertical", 1, -1,
#					0.5, Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
#			tween_loop = 0
#	tween.start()
	pass


func _on_calibration_step_changed(step: int) -> void:
#	if step == 1:
#		tween.tween_all_completed.disconnect(loop_stick_animation)
#	play_animation(step)
	pass
