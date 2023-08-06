class_name FlightController
extends Node3D


enum Controller {YAW, ROLL, PITCH, YAW_SPEED, ROLL_SPEED, PITCH_SPEED,
		ALTITUDE, POS_X, POS_Z, VERTICAL_SPEED, FORWARD_SPEED, LATERAL_SPEED,
		LAUNCH}
enum FlightMode {RATE, LEVEL, SPEED, TRACK, LAUNCH, TURTLE, AUTO}
enum ArmFail {THROTTLE_HIGH, CRASH_RECOVERY_MODE}


signal armed(mode)
signal disarmed
signal arm_failed(reason)
signal flight_mode_changed(mode)


var time := 0.0
var dt := 0.0
var pos := Vector3(0, 0, 0)
var pos_prev := pos
var angles := Vector3(0, 0, 0)
var angles_prev := angles
var lin_vel := Vector3(0, 0, 0)
var local_vel := Vector3(0, 0, 0)
var ang_vel := Vector3(0, 0, 0)
var basis_curr := Basis()
var basis_prev := basis_curr
var basis_flat := basis_curr

var motors := []
var hover_thrust := 0.0
var input: Array[float] = [0.0, 0.0, 0.0, 0.0]

var control_profile: ControlProfile = null

var state_armed := false :
	set(arm):
		state_armed = arm
		for motor in motors:
			motor.powered = state_armed
		if state_armed:
			armed.emit(flight_mode)
		else:
			disarmed.emit()

var pid_controllers: Array[PID] = []

var flight_mode: int = FlightMode.RATE

@export_range (0.0, 1000.0) var pid_roll_p := 50.0
@export_range (0.0, 1000.0) var pid_roll_i := 30.0
@export_range (0.0, 1000.0) var pid_roll_d := 30.0
@export_range (0.0, 1000.0) var pid_pitch_p := 50.0
@export_range (0.0, 1000.0) var pid_pitch_i := 30.0
@export_range (0.0, 1000.0) var pid_pitch_d := 30.0
@export_range (0.0, 1000.0) var pid_yaw_p := 70.0
@export_range (0.0, 1000.0) var pid_yaw_i := 90.0
@export_range (0.0, 1000.0) var pid_yaw_d := 40.0
var pid_scale_p := 0.004
var pid_scale_i := 0.002
var pid_scale_d := 0.0002

var telemetry_file: FileAccess = null
@export var b_telemetry := false

@onready var debug_geom := get_tree().root.get_node_or_null("Level/DebugGeometry")


func _ready() -> void:
	for _i in range(Controller.size()):
		pid_controllers.append(PID.new())

	pid_controllers[Controller.ALTITUDE].set_coefficients(
			300 * pid_scale_p, 300 * pid_scale_i, 800 * pid_scale_d)
	pid_controllers[Controller.ALTITUDE].set_clamp_limits(0.3, 0.7)
	pid_controllers[Controller.VERTICAL_SPEED].set_coefficients(
			200 * pid_scale_p, 600 * pid_scale_i, 200 * pid_scale_d)
	pid_controllers[Controller.VERTICAL_SPEED].set_clamp_limits(0.1, 1)
	pid_controllers[Controller.ROLL].set_coefficients(
			50 * pid_scale_p, 30 * pid_scale_i, 120 * pid_scale_d)
	pid_controllers[Controller.ROLL].set_clamp_limits(-0.025, 0.025)
	pid_controllers[Controller.PITCH].set_coefficients(
			50 * pid_scale_p, 30 * pid_scale_i, 120 * pid_scale_d)
	pid_controllers[Controller.PITCH].set_clamp_limits(-0.025, 0.025)

	# Clamp limits for speed controllers are equal to the maximum pitch/roll angle
	var max_angle := deg_to_rad(35)
	pid_controllers[Controller.FORWARD_SPEED].set_coefficients(
			50 * pid_scale_p, 50 * pid_scale_i, 1 * pid_scale_d)
	pid_controllers[Controller.FORWARD_SPEED].set_clamp_limits(-max_angle, max_angle)
	pid_controllers[Controller.LATERAL_SPEED].set_coefficients(
			50 * pid_scale_p, 50 * pid_scale_i, 1 * pid_scale_d)
	pid_controllers[Controller.LATERAL_SPEED].set_clamp_limits(-max_angle, max_angle)

	pid_controllers[Controller.YAW_SPEED].set_coefficients(
			pid_scale_p * pid_yaw_p, pid_scale_i * pid_yaw_i, pid_scale_d * pid_yaw_d)
	pid_controllers[Controller.YAW_SPEED].set_clamp_limits(-0.25, 0.25)
	pid_controllers[Controller.ROLL_SPEED].set_coefficients(
			pid_scale_p * pid_roll_p, pid_scale_i * pid_roll_i, pid_scale_d * pid_roll_d)
	pid_controllers[Controller.ROLL_SPEED].set_clamp_limits(-0.25, 0.25)
	pid_controllers[Controller.PITCH_SPEED].set_coefficients(
			pid_scale_p * pid_pitch_p, pid_scale_i * pid_pitch_i, pid_scale_d * pid_pitch_d)
	pid_controllers[Controller.PITCH_SPEED].set_clamp_limits(-0.25, 0.25)

	pid_controllers[Controller.POS_X].set_coefficients(0.5, 0.05, 0.3)
	pid_controllers[Controller.POS_X].set_clamp_limits(-0.5, 0.5)
	pid_controllers[Controller.POS_Z].set_coefficients(0.5, 0.05, 0.3)
	pid_controllers[Controller.POS_Z].set_clamp_limits(-0.5, 0.5)
	pid_controllers[Controller.YAW].set_coefficients(
			50 * pid_scale_p, 20 * pid_scale_i, 100 * pid_scale_d)
	pid_controllers[Controller.YAW].set_clamp_limits(-0.5, 0.5)

	pid_controllers[Controller.LAUNCH].set_coefficients(
			300 * pid_scale_p, 30 * pid_scale_i, 500 * pid_scale_d)
	pid_controllers[Controller.LAUNCH].set_clamp_limits(-0.5, 0)

	var _discard = flight_mode_changed.connect(get_parent()._on_flight_mode_changed)
	change_flight_mode.call_deferred(FlightMode.SPEED)

	if b_telemetry:
		var dir := DirAccess.open("")
		_discard = dir.remove("user://telemetry.csv")


func _physics_process(_delta: float) -> void:
	if (flight_mode == FlightMode.LEVEL or flight_mode == FlightMode.SPEED \
			or flight_mode == FlightMode.TRACK) and not is_flight_safe():
		change_flight_mode(FlightMode.AUTO)
	elif flight_mode == FlightMode.LAUNCH and (angles.x < deg_to_rad(-80) or angles.x > deg_to_rad(10)):
		_on_disarm_input()

	if flight_mode == FlightMode.TRACK:
		if debug_geom:
			debug_geom.draw_debug_cube(0.02, get_tracking_target(), Vector3(0.2, 0.2, 0.2))

	if b_telemetry:
		write_telemetry()


func set_control_profile(profile: ControlProfile) -> void:
	control_profile = profile


func _on_arm_input() -> void:
	if input[0] <= 0.01 and flight_mode != FlightMode.AUTO:
		if Input.is_action_pressed("mode_turtle"):
			change_flight_mode(FlightMode.TURTLE)
		elif Input.is_action_pressed("mode_launch"):
			change_flight_mode(FlightMode.LAUNCH)
		state_armed = true
	else:
		if input[0] > 0.01:
			arm_failed.emit(ArmFail.THROTTLE_HIGH)
		elif flight_mode == FlightMode.AUTO:
			arm_failed.emit(ArmFail.CRASH_RECOVERY_MODE)
	for controller in pid_controllers:
		controller.disabled = false


func _on_disarm_input() -> void:
	state_armed = false
	if flight_mode == FlightMode.TURTLE or flight_mode == FlightMode.LAUNCH:
		change_flight_mode(FlightMode.RATE)
	for controller in pid_controllers:
		controller.disabled = true
		controller.reset()


func integrate_loop(delta: float, drone_pos: Vector3, drone_basis: Basis) -> void:
	dt = delta
	time += dt

	pos_prev = pos
	pos = drone_pos

	basis_prev = basis_curr
	basis_curr = drone_basis
	basis_flat = Basis(Vector3(basis_curr.x.x, 0, basis_curr.x.z),
			Vector3.UP, Vector3(basis_curr.z.x, 0, basis_curr.z.z)).orthonormalized()

	angles_prev = angles
	angles = basis_curr.get_euler()

	update_velocity()

	if state_armed:
		update_control(dt)


func update_position() -> void:
	pos_prev = pos
	pos = global_transform.origin

	basis_prev = basis_curr
	basis_curr = global_transform.basis

	angles_prev = angles
	angles = basis_curr.get_euler()


func update_velocity() -> void:
	lin_vel = (pos - pos_prev) / dt
	local_vel = lin_vel * basis_curr

	var ref1 := Vector3(1, 0, 0)
	var orb1 := ((pos + basis_curr * ref1 - (pos_prev + basis_prev * ref1)) / dt - lin_vel) * basis_curr
	var omegax := (ref1.cross(orb1) / ref1.length_squared()).cross(ref1)
	var ref2 := Vector3(0, 1, 0)
	var orb2 := ((pos + basis_curr * ref2 - (pos_prev + basis_prev * ref2)) / dt - lin_vel) * basis_curr
	var omegay := (ref2.cross(orb2) / ref2.length_squared()).cross(ref2)
	var ref3 := Vector3(0, 0, 1)
	var orb3 := ((pos + basis_curr * ref3 - (pos_prev + basis_prev * ref3)) / dt - lin_vel) * basis_curr
	var omegaz := (ref3.cross(orb3) / ref3.length_squared()).cross(ref3)
	ang_vel = Vector3(omegay.z, omegaz.x, omegax.y)


func init_telemetry() -> void:
	telemetry_file = FileAccess.open("user://telemetry.csv", FileAccess.WRITE)
	if telemetry_file:
		telemetry_file.store_csv_line(["t", "input.power", "input.yaw", "input.roll", "input.pitch",
				"x", "y", "z", "vx", "vy", "vz", "vx_loc", "vy_loc", "vz_loc",
				"yaw", "roll", "pitch", "yaw_speed", "roll_speed", "pitch_speed",
				"delta_posx", "delta_posy", "delta_posz",
				"rpm1", "rpm2", "rpm3", "rpm4",
				"thrust1", "thrust2", "thrust3", "thrust4",
				"pid.alt.tgt", "pid.alt.err", "pid.alt.out", "pid.alt.clamp",
				"pid.pitch.tgt", "pid.pitch.err", "pid.pitch.out", "pid.pitch.clamp",
				"pid.roll.tgt", "pid.roll.err", "pid.roll.out", "pid.roll.clamp",
				"pid.yaw.tgt", "pid.yaw.err", "pid.yaw.out", "pid.yaw.clamp",
				"pid.yawspeed.tgt", "pid.yawspeed.err", "pid.yawspeed.out", "pid.yawspeed.clamp",
				"pid.pitchspeed.tgt", "pid.pitchspeed.err", "pid.pitchspeed.out", "pid.pitchspeed.clamp",
				"pid.rollspeed.tgt", "pid.rollspeed.err", "pid.rollspeed.out", "pid.rollspeed.clamp",
				"pid.fwdspeed.tgt", "pid.fwdspeed.err", "pid.fwdspeed.out", "pid.fwdspeed.clamp",
				"pid.latspeed.tgt", "pid.latspeed.err", "pid.latspeed.out", "pid.latspeed.clamp",
				"pid.vrtspeed.tgt", "pid.vrtspeed.err", "pid.vrtspeed.out", "pid.vrtspeed.clamp",
				"pid.posx.tgt", "pid.posx.err", "pid.posx.out", "pid.posx.clamp",
				"pid.posz.tgt", "pid.posz.err", "pid.posz.out", "pid.posz.clamp",
				"pid.launch.tgt", "pid.launch.err", "pid.launch.out", "pid.launch.clamp"])
		telemetry_file = null


func write_telemetry() -> void:
	if not FileAccess.file_exists("user://telemetry.csv"):
		init_telemetry()

	telemetry_file = FileAccess.open("user://telemetry.csv", FileAccess.READ_WRITE)
	if telemetry_file:
		telemetry_file.seek_end()
		var delta_pos := (get_tracking_target() - pos).rotated(Vector3.UP, -angles.y)
		var data := PackedStringArray([
			time,
			input[0],
			input[1],
			input[2],
			input[3],
			pos.x,
			pos.y,
			pos.z,
			lin_vel.x,
			lin_vel.y,
			lin_vel.z,
			local_vel.x,
			local_vel.y,
			local_vel.z,
			angles.y,
			angles.z,
			angles.x,
			ang_vel.y,
			ang_vel.z,
			ang_vel.x,
			delta_pos.x,
			delta_pos.y,
			delta_pos.z,
			motors[0].get_rpm(),
			motors[1].get_rpm(),
			motors[2].get_rpm(),
			motors[3].get_rpm(),
			motors[0].propeller.forces[0].length(),
			motors[1].propeller.forces[0].length(),
			motors[2].propeller.forces[0].length(),
			motors[3].propeller.forces[0].length(),
			pid_controllers[Controller.ALTITUDE].target,
			pid_controllers[Controller.ALTITUDE].err,
			pid_controllers[Controller.ALTITUDE].output,
			pid_controllers[Controller.ALTITUDE].clamped_output,
			pid_controllers[Controller.PITCH].target,
			pid_controllers[Controller.PITCH].err,
			pid_controllers[Controller.PITCH].output,
			pid_controllers[Controller.PITCH].clamped_output,
			pid_controllers[Controller.ROLL].target,
			pid_controllers[Controller.ROLL].err,
			pid_controllers[Controller.ROLL].output,
			pid_controllers[Controller.ROLL].clamped_output,
			pid_controllers[Controller.YAW].target,
			pid_controllers[Controller.YAW].err,
			pid_controllers[Controller.YAW].output,
			pid_controllers[Controller.YAW].clamped_output,
			pid_controllers[Controller.YAW_SPEED].target,
			pid_controllers[Controller.YAW_SPEED].err,
			pid_controllers[Controller.YAW_SPEED].output,
			pid_controllers[Controller.YAW_SPEED].clamped_output,
			pid_controllers[Controller.PITCH_SPEED].target,
			pid_controllers[Controller.PITCH_SPEED].err,
			pid_controllers[Controller.PITCH_SPEED].output,
			pid_controllers[Controller.PITCH_SPEED].clamped_output,
			pid_controllers[Controller.ROLL_SPEED].target,
			pid_controllers[Controller.ROLL_SPEED].err,
			pid_controllers[Controller.ROLL_SPEED].output,
			pid_controllers[Controller.ROLL_SPEED].clamped_output,
			pid_controllers[Controller.FORWARD_SPEED].target,
			pid_controllers[Controller.FORWARD_SPEED].err,
			pid_controllers[Controller.FORWARD_SPEED].output,
			pid_controllers[Controller.FORWARD_SPEED].clamped_output,
			pid_controllers[Controller.LATERAL_SPEED].target,
			pid_controllers[Controller.LATERAL_SPEED].err,
			pid_controllers[Controller.LATERAL_SPEED].output,
			pid_controllers[Controller.LATERAL_SPEED].clamped_output,
			pid_controllers[Controller.VERTICAL_SPEED].target,
			pid_controllers[Controller.VERTICAL_SPEED].err,
			pid_controllers[Controller.VERTICAL_SPEED].output,
			pid_controllers[Controller.VERTICAL_SPEED].clamped_output,
			pid_controllers[Controller.POS_X].target,
			pid_controllers[Controller.POS_X].err,
			pid_controllers[Controller.POS_X].output,
			pid_controllers[Controller.POS_X].clamped_output,
			pid_controllers[Controller.POS_Z].target,
			pid_controllers[Controller.POS_Z].err,
			pid_controllers[Controller.POS_Z].output,
			pid_controllers[Controller.POS_Z].clamped_output,
			pid_controllers[Controller.LAUNCH].target,
			pid_controllers[Controller.LAUNCH].err,
			pid_controllers[Controller.LAUNCH].output,
			pid_controllers[Controller.LAUNCH].clamped_output,
		])
		telemetry_file.store_csv_line(data)
		telemetry_file = null


func change_flight_mode(mode: int) -> void:
	flight_mode = mode
	flight_mode_changed.emit(flight_mode)
	print("Mode: %s" % [flight_mode])


func _on_cycle_flight_modes() -> void:
	if flight_mode == FlightMode.TURTLE or flight_mode == FlightMode.LAUNCH:
		return
	flight_mode += 1
	while (
			flight_mode == FlightMode.AUTO
			or flight_mode == FlightMode.TURTLE
			or flight_mode == FlightMode.LAUNCH
	):
		flight_mode += 1
	if flight_mode >= FlightMode.size():
		flight_mode = 0
	change_flight_mode(flight_mode)

	if flight_mode == FlightMode.LEVEL:
		pid_controllers[Controller.ALTITUDE].target = pos.y
	if flight_mode == FlightMode.TRACK:
		pid_controllers[Controller.ALTITUDE].target = pos.y
		pid_controllers[Controller.POS_X].target = pos.x
		pid_controllers[Controller.POS_Z].target = pos.z
		pid_controllers[Controller.YAW].target = angles.y


func get_angles_from_basis() -> void:
	angles = global_transform.basis.get_euler()


func is_flight_safe() -> bool:
	var max_angle := deg_to_rad(50)
	var safe := true
	if absf(angles.x) > max_angle or absf(angles.z) > max_angle:
		safe = false
	return safe


func set_motors(motor_array: Array) -> void:
	motors = motor_array
	for motor in motors:
		var _discard = armed.connect(motor._on_armed)


func set_hover_thrust(t: float) -> void:
	hover_thrust = t


func set_tracking_target(target: Vector3) -> void:
	pid_controllers[Controller.POS_X].target = target.x
	pid_controllers[Controller.ALTITUDE].target = target.y
	pid_controllers[Controller.POS_Z].target = target.z


func get_tracking_target() -> Vector3:
	return Vector3(
		pid_controllers[Controller.POS_X].target,
		pid_controllers[Controller.ALTITUDE].target,
		pid_controllers[Controller.POS_Z].target
	)


func update_control(delta: float) -> void:
	dt = delta
	var motor_control := update_command()
#	print("%8.3f %8.3f %8.3f %8.3f" % [power, yaw, roll, pitch])

	var power := motor_control[0]
	var yaw := motor_control[1]
	var roll := motor_control[2]
	var pitch := motor_control[3]
	var motor_pwm: Array[float] = [
			power + yaw + roll + pitch,
			power - yaw - roll + pitch,
			power + yaw - roll - pitch,
			power - yaw + roll - pitch,
	]

	# Air Mode
	var pwm_min := motor_pwm.min() as float
	var pwm_max := motor_pwm.max() as float
	var idle_pwm := motors[0].MIN_POWER / 100.0 as float
	# Scale PWM to range [idle, 1] as needed
	if pwm_max - pwm_min > 1 - idle_pwm:
		var pwm_mid := (pwm_min + pwm_max) / 2.0
		for i in range(4):
			motor_pwm[i] = pwm_mid + (motor_pwm[i] - pwm_mid) * (1 - idle_pwm) / (pwm_max - pwm_min)
	pwm_min = motor_pwm.min()
	pwm_max = motor_pwm.max()
	var offset := 0.0
	if pwm_min < idle_pwm:
		offset = idle_pwm - pwm_min
	if pwm_max > 1:
		offset = 1 - pwm_max
	for i in range(4):
		motor_pwm[i] += offset

	if flight_mode == FlightMode.TURTLE:
		motor_pwm = [0.0, 0.0, 0.0, 0.0]
		if absf(roll) > absf(pitch):
			if absf(roll) > 0.2:
				if roll > 0:
					motor_pwm[1] = -roll
					motor_pwm[2] = -roll
				else:
					motor_pwm[0] = roll
					motor_pwm[3] = roll
		else:
			if absf(pitch) > 0.2:
				if pitch > 0:
					motor_pwm[2] = -pitch
					motor_pwm[3] = -pitch
				else:
					motor_pwm[0] = pitch
					motor_pwm[1] = pitch

	elif flight_mode == FlightMode.LAUNCH:
		motor_pwm = [idle_pwm, idle_pwm, idle_pwm, idle_pwm]
		motor_pwm[2] = clampf(-pitch, idle_pwm, 1)
		motor_pwm[3] = clampf(-pitch, idle_pwm, 1)
		if power > 0.2:
			motor_pwm = [-pitch, -pitch, -pitch, -pitch]
			change_flight_mode(FlightMode.RATE)

	motors[0].set_pwm(motor_pwm[0])
	motors[1].set_pwm(motor_pwm[1])
	motors[2].set_pwm(motor_pwm[2])
	motors[3].set_pwm(motor_pwm[3])


func update_command() -> Array[float]:
	var motor_control: Array[float] = [0.0, 0.0, 0.0, 0.0]

	var pwr := input[0]
	var y := input[1]
	var r := input[2]
	var p := input[3]

	var yaw_input := control_profile.get_normalized_axis_command(ControlProfile.Axis.YAW, y)
	var roll_input := control_profile.get_normalized_axis_command(ControlProfile.Axis.ROLL, r)
	var pitch_input := control_profile.get_normalized_axis_command(ControlProfile.Axis.PITCH, p)

	if flight_mode == FlightMode.RATE:
		motor_control[0] = pwr

		pid_controllers[Controller.YAW_SPEED].target = deg_to_rad(-yaw_input \
				* control_profile.get_max_rate(ControlProfile.Axis.YAW))
		motor_control[1] = pid_controllers[Controller.YAW_SPEED].get_output(ang_vel.y, dt, false)

		pid_controllers[Controller.ROLL_SPEED].target = deg_to_rad(roll_input \
				* control_profile.get_max_rate(ControlProfile.Axis.ROLL))
		motor_control[2] = pid_controllers[Controller.ROLL_SPEED].get_output(-ang_vel.z, dt, false)

		pid_controllers[Controller.PITCH_SPEED].target = deg_to_rad(pitch_input \
				* control_profile.get_max_rate(ControlProfile.Axis.PITCH))
		motor_control[3] = pid_controllers[Controller.PITCH_SPEED].get_output(ang_vel.x, dt, false)

	elif flight_mode == FlightMode.LEVEL:
		motor_control[0] = pwr

		pid_controllers[Controller.YAW_SPEED].target = -yaw_input * 2 * PI
		motor_control[1] = pid_controllers[Controller.YAW_SPEED].get_output(ang_vel.y, dt, false)

		var bank_limit := deg_to_rad(35)
		pid_controllers[Controller.ROLL].target = roll_input * bank_limit
		motor_control[2] = pid_controllers[Controller.ROLL].get_output(-angles.z, dt)

		pid_controllers[Controller.PITCH].target = pitch_input * bank_limit
		motor_control[3] = pid_controllers[Controller.PITCH].get_output(angles.x, dt, false)

	elif flight_mode == FlightMode.SPEED:
		var vertical_speed := 10.0
		pid_controllers[Controller.VERTICAL_SPEED].target = (pwr - 0.5) * vertical_speed
		motor_control[0] = pid_controllers[Controller.VERTICAL_SPEED].get_output(lin_vel.y, dt, false)

		pid_controllers[Controller.YAW_SPEED].target = -yaw_input * 2
		motor_control[1] = pid_controllers[Controller.YAW_SPEED].get_output(ang_vel.y, dt, false)

		var bank_limit := deg_to_rad(35)
		var speed_limit := 10.0
		var flat_vel := lin_vel * basis_flat
		pid_controllers[Controller.LATERAL_SPEED].target = roll_input * speed_limit
		var roll_change := pid_controllers[Controller.LATERAL_SPEED].get_output(flat_vel.x, dt, false)
		pid_controllers[Controller.ROLL].target = clampf(roll_change, -bank_limit, bank_limit)
		motor_control[2] = pid_controllers[Controller.ROLL].get_output(-angles.z, dt, false)

		pid_controllers[Controller.FORWARD_SPEED].target = pitch_input * speed_limit
		var pitch_change := pid_controllers[Controller.FORWARD_SPEED].get_output(flat_vel.z, dt, false)
		pid_controllers[Controller.PITCH].target = clampf(pitch_change, -bank_limit, bank_limit)
		motor_control[3] = pid_controllers[Controller.PITCH].get_output(angles.x, dt, false)

	elif flight_mode == FlightMode.TRACK:
		var target := get_tracking_target()
		var target_prev := target
		var target_speed := 5.0
		target.x = target.x + roll_input * target_speed * dt
		target.y = target.y + (pwr - 0.5) * target_speed * dt
		target.z = target.z + pitch_input * target_speed * dt
		set_tracking_target(target)

		motor_control[0] = pid_controllers[Controller.ALTITUDE].get_output(pos.y, dt, false)

		var target_angle := pid_controllers[Controller.YAW].target - yaw_input * PI / 2.0 * dt
		while target_angle > PI:
			target_angle -= 2 * PI
		while target_angle < -PI:
			target_angle += 2 * PI
		pid_controllers[Controller.YAW].target = target_angle
		var hdg_delta := 0.0
		if absf(target_angle - angles.y) > PI:
			hdg_delta = 2 * PI
			if target_angle < 0:
				hdg_delta = -hdg_delta
		var measurement := angles.y + hdg_delta
		# Manually correct previous PID measurement to remove discontinuity
		if absf(pid_controllers[Controller.YAW].mv_prev - measurement) > PI:
			pid_controllers[Controller.YAW].mv_prev += hdg_delta
		motor_control[1] = pid_controllers[Controller.YAW].get_output(measurement, dt, false)

		var xform := Transform3D(basis_curr, pos)
		target = get_tracking_target()
		var delta_pos: Vector3 = target * xform
		var target_vel := (target - target_prev) / dt

		var bank_limit := deg_to_rad(35)
		if lin_vel.length() > 2.8 or target_vel.length() > 2.8 or delta_pos.length() > 3.0:
			pid_controllers[Controller.LATERAL_SPEED].target = (target_vel * basis_curr).x + 2 * delta_pos.x
			var roll_change := pid_controllers[Controller.LATERAL_SPEED].get_output(local_vel.x, dt, false)
			pid_controllers[Controller.ROLL].target = clampf(roll_change, -bank_limit, bank_limit)
			motor_control[2] = pid_controllers[Controller.ROLL].get_output(-angles.z, dt, false)

			pid_controllers[Controller.FORWARD_SPEED].target = (target_vel * basis_curr).z + 2 * delta_pos.z
			var pitch_change := pid_controllers[Controller.FORWARD_SPEED].get_output(local_vel.z, dt, false)
			pid_controllers[Controller.PITCH].target = clampf(pitch_change, -bank_limit, bank_limit)
			motor_control[3] = pid_controllers[Controller.PITCH].get_output(angles.x, dt, false)
		else:
			var roll_target := pid_controllers[Controller.POS_X].get_output(target.x - delta_pos.x, dt)
			pid_controllers[Controller.ROLL].target = clampf(roll_target,-bank_limit, bank_limit)
			motor_control[2] = pid_controllers[Controller.ROLL].get_output(-angles.z, dt)

			var pitch_target := pid_controllers[Controller.POS_Z].get_output(target.z - delta_pos.z, dt)
			pid_controllers[Controller.PITCH].target = clampf(pitch_target,-bank_limit, bank_limit)
			motor_control[3] = pid_controllers[Controller.PITCH].get_output(angles.x, dt)

	elif flight_mode == FlightMode.TURTLE:
		motor_control[0] = 0.0
		motor_control[1] = 0.0
		if absf(p) > absf(r):
			motor_control[2] = 0.0
			motor_control[3] = p
		else:
			motor_control[2] = r
			motor_control[3] = 0.0

	elif flight_mode == FlightMode.LAUNCH:
		motor_control[0] = pwr

		pid_controllers[Controller.LAUNCH].target += pitch_input * dt
		motor_control[3] = pid_controllers[Controller.LAUNCH].get_output(angles.x, dt, false)

	elif flight_mode == FlightMode.AUTO:
		pid_controllers[Controller.YAW_SPEED].target = 0
		motor_control[1] = pid_controllers[Controller.YAW_SPEED].get_output(ang_vel.y, dt, false)

		var bank_limit := deg_to_rad(20)
		if is_flight_safe():
			var target_speed := -5.0
			if pos.y < 1:
				_on_disarm_input()
			pid_controllers[Controller.VERTICAL_SPEED].target = target_speed
			motor_control[0] = pid_controllers[Controller.VERTICAL_SPEED].get_output(lin_vel.y, dt, false)

			pid_controllers[Controller.LATERAL_SPEED].target = 0
			var roll_change := pid_controllers[Controller.LATERAL_SPEED].get_output(local_vel.x, dt, false)
			pid_controllers[Controller.ROLL].target = clampf(roll_change, -bank_limit, bank_limit)
			motor_control[2] = pid_controllers[Controller.ROLL].get_output(-angles.z, dt, false)

			pid_controllers[Controller.FORWARD_SPEED].target = 0
			var pitch_change := pid_controllers[Controller.FORWARD_SPEED].get_output(local_vel.z, dt, false)
			pid_controllers[Controller.PITCH].target = clampf(pitch_change, -bank_limit, bank_limit)
			motor_control[3] = pid_controllers[Controller.PITCH].get_output(angles.x, dt, false)
		else:
			if ang_vel.length_squared() <= deg_to_rad(360):
				pid_controllers[Controller.ROLL].target = 0
				motor_control[2] = pid_controllers[Controller.ROLL].get_output(-angles.z, dt, false)
				pid_controllers[Controller.PITCH].target = 0
				motor_control[3] = pid_controllers[Controller.PITCH].get_output(angles.x, dt, false)
			else:
				pid_controllers[Controller.ROLL_SPEED].target = 0
				motor_control[2] = pid_controllers[Controller.ROLL_SPEED].get_output(-ang_vel.z, dt, false)
				pid_controllers[Controller.PITCH_SPEED].target = 0
				motor_control[3] = pid_controllers[Controller.PITCH_SPEED].get_output(ang_vel.x, dt, false)
	return motor_control


func reset() -> void:
	state_armed = false

	# Update position twice to ensure pos_prev == pos
	for _i in range(2):
		update_position()
	update_velocity()

	for controller in pid_controllers:
		controller.reset()
	pid_controllers[Controller.ALTITUDE].target = pos.y
	pid_controllers[Controller.POS_X].target = pos.x
	pid_controllers[Controller.POS_Z].target = pos.z

	for motor in motors:
		motor.rpm = 0
