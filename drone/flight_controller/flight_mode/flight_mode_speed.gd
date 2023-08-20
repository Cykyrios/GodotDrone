class_name FlightModeSpeed
extends FlightMode


var pid_pitch: PID = null
var pid_roll: PID = null
var pid_yaw: PID = null
var pid_speed_forward: PID = null
var pid_speed_side: PID = null
var pid_speed_vertical: PID = null

var max_angle := 35.0
var max_h_speed := 10.0
var max_v_speed := 10.0


func _init() -> void:
	type = Type.SPEED


func _to_string() -> String:
	return "SPEED"


func _get_command(input: FlightCommand) -> FlightCommand:
	var flight_command := FlightCommand.new()
	var lin_vel := flight_state.velocity
	var angles := flight_state.orientation
	var ang_vel := flight_state.angular_velocity
	var basis := flight_state.basis
	var basis_flat := Basis(Vector3(basis.x.x, 0, basis.x.z),
			Vector3.UP, Vector3(basis.z.x, 0, basis.z.z)).orthonormalized()

	pid_speed_vertical.target = (input.power - 0.5) * max_v_speed
	flight_command.power = pid_speed_vertical.get_output(lin_vel.y, dt, false)

	pid_yaw.target = -input.yaw * 2
	flight_command.yaw = pid_yaw.get_output(ang_vel.y, dt, false)

	var bank_limit := deg_to_rad(max_angle)
	var flat_vel := lin_vel * basis_flat
	pid_speed_side.target = input.roll * max_h_speed
	var roll_change := pid_speed_side.get_output(flat_vel.x, dt, false)
	pid_roll.target = clampf(roll_change, -bank_limit, bank_limit)
	flight_command.roll = pid_roll.get_output(-angles.z, dt, false)

	pid_speed_forward.target = input.pitch * max_h_speed
	var pitch_change := pid_speed_forward.get_output(flat_vel.z, dt, false)
	pid_pitch.target = clampf(pitch_change, -bank_limit, bank_limit)
	flight_command.pitch = pid_pitch.get_output(angles.x, dt, false)

	return flight_command
