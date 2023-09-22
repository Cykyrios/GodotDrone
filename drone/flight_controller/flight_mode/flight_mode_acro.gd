class_name FlightModeAcro
extends FlightMode


var pid_pitch: PID = null
var pid_roll: PID = null
var pid_yaw: PID = null


func _init() -> void:
	type = Type.ACRO


func _to_string() -> String:
	return "ACRO"


func _get_command(input: FlightCommand) -> FlightCommand:
	var flight_command := FlightCommand.new()
	var ang_vel := flight_state.angular_velocity

	flight_command.power = input.power

	pid_yaw.target = deg_to_rad(-input.yaw * control_profile.get_max_rate(ControlProfile.Axis.YAW))
	flight_command.yaw = pid_yaw.get_output(ang_vel.y, dt, false)

	pid_roll.target = deg_to_rad(input.roll * control_profile.get_max_rate(ControlProfile.Axis.ROLL))
	flight_command.roll = pid_roll.get_output(-ang_vel.z, dt, false)

	pid_pitch.target = deg_to_rad(input.pitch * control_profile.get_max_rate(ControlProfile.Axis.PITCH))
	flight_command.pitch = pid_pitch.get_output(ang_vel.x, dt, false)

	return flight_command
