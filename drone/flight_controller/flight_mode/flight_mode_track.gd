class_name FlightModeTrack
extends FlightMode


var pid_pitch: PID = null
var pid_roll: PID = null
var pid_yaw: PID = null
var pid_altitude: PID = null
var pid_pos_x: PID = null
var pid_pos_z: PID = null
var pid_speed_forward: PID = null
var pid_speed_side: PID = null


func _init() -> void:
	type = Type.TRACK


func _to_string() -> String:
	return "POSITION"


func _get_command(input: FlightCommand) -> FlightCommand:
	var flight_command := FlightCommand.new()
	var angles := flight_state.orientation
	var basis := flight_state.basis
	var local_vel := flight_state.velocity * basis

	var target := get_tracking_target()
	var target_prev := target
	var target_speed := 5.0
	target.x = target.x + input.roll * target_speed * dt
	target.y = target.y + (input.power - 0.5) * target_speed * dt
	target.z = target.z + input.pitch * target_speed * dt
	set_tracking_target(target)

	flight_command.power = pid_altitude.get_output(flight_state.position.y, dt, false)

	var target_angle := pid_yaw.target - input.yaw * PI / 2.0 * dt
	while target_angle > PI:
		target_angle -= 2 * PI
	while target_angle < -PI:
		target_angle += 2 * PI
	pid_yaw.target = target_angle
	var hdg_delta := 0.0
	if absf(target_angle - angles.y) > PI:
		hdg_delta = 2 * PI
		if target_angle < 0:
			hdg_delta = -hdg_delta
	var measurement := angles.y + hdg_delta
	# Manually correct previous PID measurement to remove discontinuity
	if absf(pid_yaw.mv_prev - measurement) > PI:
		pid_yaw.mv_prev += hdg_delta
	flight_command.yaw = pid_yaw.get_output(measurement, dt, false)

	var xform := Transform3D(basis, flight_state.position)
	target = get_tracking_target()
	var delta_pos: Vector3 = target * xform
	var target_vel := (target - target_prev) / dt

	var bank_limit := deg_to_rad(35)
	if (
		flight_state.velocity.length() > 2.8
		or target_vel.length() > 2.8
		or delta_pos.length() > 3.0
	):
		pid_speed_side.target = (target_vel * basis).x + 2 * delta_pos.x
		var roll_change := pid_speed_side.get_output(local_vel.x, dt, false)
		pid_roll.target = clampf(roll_change, -bank_limit, bank_limit)
		flight_command.roll = pid_roll.get_output(-angles.z, dt, false)

		pid_speed_forward.target = (target_vel * basis).z + 2 * delta_pos.z
		var pitch_change := pid_speed_forward.get_output(local_vel.z, dt, false)
		pid_pitch.target = clampf(pitch_change, -bank_limit, bank_limit)
		flight_command.pitch = pid_pitch.get_output(angles.x, dt, false)
	else:
		var roll_target := pid_pos_x.get_output(target.x - delta_pos.x, dt)
		pid_roll.target = clampf(roll_target,-bank_limit, bank_limit)
		flight_command.roll = pid_roll.get_output(-angles.z, dt)

		var pitch_target := pid_pos_z.get_output(target.z - delta_pos.z, dt)
		pid_pitch.target = clampf(pitch_target,-bank_limit, bank_limit)
		flight_command.pitch = pid_pitch.get_output(angles.x, dt)

	return flight_command


func get_tracking_target() -> Vector3:
	return Vector3(pid_pos_x.target, pid_altitude.target, pid_pos_z.target)


func set_tracking_target(target: Vector3) -> void:
	pid_pos_x.target = target.x
	pid_altitude.target = target.y
	pid_pos_z.target = target.z
