class_name FlightModeHorizon
extends FlightMode


var pid_pitch: PID = null
var pid_roll: PID = null
var pid_yaw: PID = null


func _init() -> void:
	type = Type.HORIZON


func _to_string() -> String:
	return "HORIZON"


func _get_command(input: FlightCommand) -> FlightCommand:
	var flight_command := FlightCommand.new()
	var angles := flight_state.orientation

	flight_command.power = input.power

	pid_yaw.target = -input.yaw * 2 * PI
	flight_command.yaw = pid_yaw.get_output(flight_state.angular_velocity.y, dt, false)

	var bank_limit := deg_to_rad(35)
	pid_roll.target = input.roll * bank_limit
	flight_command.roll = pid_roll.get_output(-angles.z, dt)

	pid_pitch.target = input.pitch * bank_limit
	flight_command.pitch = pid_pitch.get_output(angles.x, dt, false)

	return flight_command
