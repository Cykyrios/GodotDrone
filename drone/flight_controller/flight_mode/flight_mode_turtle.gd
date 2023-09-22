class_name FlightModeTurtle
extends FlightMode


func _init() -> void:
	type = Type.TURTLE


func _to_string() -> String:
	return "TURTLE"


func _get_command(input: FlightCommand) -> FlightCommand:
	var flight_command := FlightCommand.new()

	var pitch_input := input.pitch
	var roll_input := input.roll

	flight_command.power = 0.0
	flight_command.yaw = 0.0
	if absf(pitch_input) > absf(roll_input):
		flight_command.roll = 0.0
		flight_command.pitch = pitch_input
	else:
		flight_command.roll = roll_input
		flight_command.pitch = 0.0

	return flight_command
