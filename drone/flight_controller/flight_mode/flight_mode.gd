class_name FlightMode
extends RefCounted


enum Type{ACRO, HORIZON, SPEED, TRACK, LAUNCH, TURTLE, RECOVER}

var type: Type

var dt := 0.0
var flight_state: FlightState = null
var control_profile: ControlProfile = null
var safe_flight := true


func _init() -> void:
	type = Type.ACRO


func _to_string() -> String:
	return "NONE"


func get_command(input: FlightCommand) -> FlightCommand:
	return _get_command(input)


func update_control_profile(new_control_profile: ControlProfile) -> void:
	control_profile = new_control_profile


func update_loop_dt(delta: float) -> void:
	dt = delta


func update_state(new_flight_state: FlightState) -> void:
	flight_state = new_flight_state


func _get_command(input: FlightCommand) -> FlightCommand:
	return input
