class_name FlightModeRecover
extends FlightMode


signal disarm_requested

var pid_pitch_speed : PID = null
var pid_roll_speed : PID = null
var pid_pitch : PID = null
var pid_roll : PID = null
var pid_yaw : PID = null
var pid_speed_forward : PID = null
var pid_speed_side : PID = null
var pid_speed_vertical : PID = null


func _init() -> void:
	type = Type.RECOVER


func _to_string() -> String:
	return "RECOVER"


func _get_command(_input: FlightCommand) -> FlightCommand:
	var flight_command := FlightCommand.new()
	var angles := flight_state.orientation
	var ang_vel := flight_state.angular_velocity
	var local_vel := flight_state.velocity * flight_state.basis

	pid_yaw.target = 0
	flight_command.yaw = pid_yaw.get_output(ang_vel.y, dt, false)

	var bank_limit := deg_to_rad(20)
	if safe_flight:
		var target_speed := -5.0
		if flight_state.position.y < 1:
			disarm_requested.emit()
		pid_speed_vertical.target = target_speed
		flight_command.power = pid_speed_vertical.get_output(flight_state.velocity.y, dt, false)

		pid_speed_side.target = 0
		var roll_change := pid_speed_side.get_output(local_vel.x, dt, false)
		pid_roll.target = clampf(roll_change, -bank_limit, bank_limit)
		flight_command.roll = pid_roll.get_output(-angles.z, dt, false)

		pid_speed_forward.target = 0
		var pitch_change := pid_speed_forward.get_output(local_vel.z, dt, false)
		pid_pitch.target = clampf(pitch_change, -bank_limit, bank_limit)
		flight_command.pitch = pid_pitch.get_output(angles.x, dt, false)
	else:
		if ang_vel.length_squared() <= deg_to_rad(360):
			pid_roll.target = 0
			flight_command.roll = pid_roll.get_output(-angles.z, dt, false)
			pid_pitch.target = 0
			flight_command.pitch = pid_pitch.get_output(angles.x, dt, false)
		else:
			pid_roll_speed.target = 0
			flight_command.roll = pid_roll_speed.get_output(-ang_vel.z, dt, false)
			pid_pitch_speed.target = 0
			flight_command.pitch = pid_pitch_speed.get_output(ang_vel.x, dt, false)

	return flight_command
