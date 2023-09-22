class_name FlightModeLaunch
extends FlightMode


var pid_launch: PID = null


func _init() -> void:
	type = Type.LAUNCH


func _to_string() -> String:
	return "LAUNCH"


func _get_command(input: FlightCommand) -> FlightCommand:
	var flight_command := FlightCommand.new()
	var angles := flight_state.orientation

	flight_command.power = input.power

	pid_launch.target += input.pitch * dt
	flight_command.pitch = pid_launch.get_output(angles.x, dt, false)

	return flight_command
