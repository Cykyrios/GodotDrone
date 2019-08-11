extends Spatial

class_name FlightController

var t = 0.0
var dt = 0.0
var pos = Vector3(0, 0, 0)
var pos_prev = pos
var angles = Vector3(0, 0, 0)
var angles_prev = angles
var lin_vel = Vector3(0, 0, 0)
var ang_vel = Vector3(0, 0, 0)

var props = []
var hover_thrust = 0.0
var input = [0, 0, 0, 0]

var pid_controllers = []
enum Controller {YAW, ROLL, PITCH, YAW_SPEED, ROLL_SPEED, PITCH_SPEED,
		ALTITUDE, POS_X, POS_Z, VERTICAL_SPEED, FORWARD_SPEED, LATERAL_SPEED,
		HEADING}

enum FlightMode {RATE, LEVEL, SPEED, TRACK, AUTO}
var flight_mode = FlightMode.RATE

var telemetry_file = File.new()
var b_telemetry = true

signal flight_mode_changed

onready var debug_geom = get_tree().root.get_node("Level/DebugGeometry")


func _ready():
	pos = global_transform.origin
	angles = global_transform.basis.get_euler()
	
	for i in range(Controller.size()):
		pid_controllers.append(PID.new())
	
	pid_controllers[Controller.ALTITUDE].set_coefficients(10, 2, 3)
	pid_controllers[Controller.ALTITUDE].set_clamp_limits(0.1, 10)
	pid_controllers[Controller.VERTICAL_SPEED].set_coefficients(30, 5, 1)
#	pid_controllers[Controller.VERTICAL_SPEED].set_clamp_limits(-2, 2)
	pid_controllers[Controller.ROLL].set_coefficients(5, 1, 2)
#	pid_controllers[Controller.ROLL].set_clamp_limits(-0.5, 0.5)
	pid_controllers[Controller.PITCH].set_coefficients(5, 1, 2)
#	pid_controllers[Controller.PITCH].set_clamp_limits(-0.5, 0.5)
	
	pid_controllers[Controller.FORWARD_SPEED].set_coefficients(0.2, 0.0, 0.01)
	pid_controllers[Controller.FORWARD_SPEED].set_clamp_limits(-0.5, 0.5)
	pid_controllers[Controller.LATERAL_SPEED].set_coefficients(0.2, 0.0, 0.01)
	pid_controllers[Controller.LATERAL_SPEED].set_clamp_limits(-0.5, 0.5)
	
	pid_controllers[Controller.YAW_SPEED].set_coefficients(3, 0.0, 0.1)
#	pid_controllers[Controller.YAW_SPEED].set_clamp_limits(-1, 1)
	pid_controllers[Controller.ROLL_SPEED].set_coefficients(3, 0, 0.1)
#	pid_controllers[Controller.ROLL_SPEED].set_clamp_limits(-1, 1)
	pid_controllers[Controller.PITCH_SPEED].set_coefficients(3, 0, 0.1)
#	pid_controllers[Controller.PITCH_SPEED].set_clamp_limits(-1, 1)
	
	pid_controllers[Controller.POS_X].set_coefficients(0.4, 0, 0.2)
	pid_controllers[Controller.POS_X].set_clamp_limits(-1, 1)
	pid_controllers[Controller.POS_Z].set_coefficients(0.4, 0, 0.2)
	pid_controllers[Controller.POS_Z].set_clamp_limits(-1, 1)
	pid_controllers[Controller.HEADING].set_coefficients(3, 0, 2)
#	pid_controllers[Controller.HEADING].set_clamp_limits(-1, 1)
	
	connect("flight_mode_changed", get_parent(), "_on_flight_mode_changed")
	flight_mode = FlightMode.SPEED
	emit_signal("flight_mode_changed", flight_mode)
	
	if b_telemetry:
		var dir = Directory.new()
		dir.remove("user://telemetry.csv")


#func _process(delta):
#	pass


func _physics_process(delta):
	dt = delta
	t += dt
	
	pos_prev = pos
	pos = global_transform.origin
	lin_vel = (pos - pos_prev) / dt
	
	angles_prev = angles
	angles = global_transform.basis.get_euler()
	ang_vel = (angles - angles_prev) / dt
	
#	print("px %6.2f py %6.2f pz %6.2f, vx %6.2f vy %6.2f vz %6.2f, ax %6.2f ay %6.2f az %6.2f, wx %6.2f wy %6.2f wz %6.2f"
#			% [pos.x, pos.y, pos.z, lin_vel.x, lin_vel.y, lin_vel.z,
#			angles.x, angles.y, angles.z, ang_vel.x, ang_vel.y, ang_vel.z])
	
	if !is_flight_safe():
		if flight_mode != FlightMode.RATE:
			flight_mode = FlightMode.AUTO
			emit_signal("flight_mode_changed", flight_mode)
	
	read_input()
	update_control(delta)
	
	if flight_mode == FlightMode.TRACK:
		debug_geom.draw_debug_cube(0.02, get_tracking_target(), Vector3(0.2, 0.2, 0.2))
	
	if b_telemetry:
		write_telemetry()


func init_telemetry():
	telemetry_file.open("user://telemetry.csv", File.WRITE)
	telemetry_file.store_csv_line(["t", "input.power", "input.yaw", "input.roll", "input.pitch",
			"x", "y", "z", "vx", "vy", "vz",
			"yaw", "roll", "pitch", "yaw_speed", "roll_speed", "pitch_speed",
			"rpm1", "rpm2", "rpm3", "rpm4",
			"thrust1", "thrust2", "thrust3", "thrust4"])
	telemetry_file.close()


func write_telemetry():
	if !telemetry_file.file_exists("user://telemetry.csv"):
		init_telemetry()
	
	telemetry_file.open("user://telemetry.csv", File.READ_WRITE)
	telemetry_file.seek_end()
	var data = PoolStringArray([t, input[0], input[1], input[2], input[3],
			pos.x, pos.y, pos.z, lin_vel.x, lin_vel.y, lin_vel.z,
			angles.y, angles.z, angles.x, ang_vel.y, ang_vel.z, ang_vel.x,
			props[0].get_rpm(), props[1].get_rpm(), props[2].get_rpm(), props[3].get_rpm(),
			props[0].get_thrust(), props[1].get_thrust(), props[2].get_thrust(), props[3].get_thrust()])
	telemetry_file.store_csv_line(data)
	telemetry_file.close()


func _input(event):
	if event.is_action_pressed("cycle_flight_modes"):
		cycle_flight_modes()


func cycle_flight_modes():
	if flight_mode == FlightMode.AUTO or flight_mode == FlightMode.AUTO - 1:
		flight_mode = 0
	else:
		flight_mode += 1
	print("Mode: %s" % [flight_mode])
	
	emit_signal("flight_mode_changed", flight_mode)
	
	if flight_mode == FlightMode.LEVEL:
		pid_controllers[Controller.ALTITUDE].set_target(pos.y)
	if flight_mode == FlightMode.TRACK:
		pid_controllers[Controller.ALTITUDE].set_target(pos.y)
		pid_controllers[Controller.POS_X].set_target(pos.x)
		pid_controllers[Controller.POS_Z].set_target(pos.z)
		pid_controllers[Controller.HEADING].set_target(angles.y)


func get_angles_from_basis():
#	var heading = 0.0
#	var pitch = 0.0
#	var roll = 0.0
	angles = global_transform.basis.get_euler()


func is_flight_safe():
	var safe = true
	if abs(angles.x) > PI / 4 or abs(angles.z) > PI / 4:
		safe = false
	return safe


func set_props(prop_array):
	props = prop_array


func set_hover_thrust(t : float):
	hover_thrust = t


func get_tracking_target():
	var target = Vector3(pid_controllers[Controller.POS_X].target, pid_controllers[Controller.ALTITUDE].target,
			pid_controllers[Controller.POS_Z].target)
	return target


func read_input():
	var power = (Input.get_action_strength("increase_power") - Input.get_action_strength("decrease_power") + 1) / 2
	var pitch = Input.get_action_strength("pitch_up") - Input.get_action_strength("pitch_down")
	var roll = Input.get_action_strength("roll_right") - Input.get_action_strength("roll_left")
	var yaw = Input.get_action_strength("yaw_right") - Input.get_action_strength("yaw_left")
#	print("Pow: %8.2f ptc: %6.3f rol: %6.3f yaw: %6.3f" % [power, pitch, roll, yaw])
	input = [power, yaw, roll, pitch]


func update_control(delta):
	dt = delta
	var power = change_power(input[0])
	var yaw = change_yaw(input[1])
	var roll = change_roll(input[2])
	var pitch = change_pitch(input[3])
	
	props[0].set_thrust_target(power - yaw + roll + pitch)
	props[1].set_thrust_target(power + yaw - roll + pitch)
	props[2].set_thrust_target(power - yaw - roll - pitch)
	props[3].set_thrust_target(power + yaw + roll - pitch)


func change_power(p):
	var power = hover_thrust
	
	if flight_mode == FlightMode.RATE:
		power += sign(p) * pow(abs(p), 2) * 50 - 10
	
	elif flight_mode == FlightMode.SPEED:
		pid_controllers[Controller.VERTICAL_SPEED].set_target((p - 0.5) * 4)
		power += pid_controllers[Controller.VERTICAL_SPEED].get_output(lin_vel.y, dt, false)
	
	elif flight_mode == FlightMode.LEVEL or flight_mode == FlightMode.TRACK:
		var target = pid_controllers[Controller.ALTITUDE].target
		pid_controllers[Controller.ALTITUDE].set_target(target + (p - 0.5) / 40)
		power += pid_controllers[Controller.ALTITUDE].get_output(pos.y, dt, false)
	
	elif flight_mode == FlightMode.AUTO:
		if is_flight_safe():
			pid_controllers[Controller.VERTICAL_SPEED].set_target(0)
			power = pid_controllers[Controller.VERTICAL_SPEED].get_output(lin_vel.y, dt, false)
	
	return power


func change_pitch(p):
	var pitch_change = 0.0
	
	if flight_mode == FlightMode.RATE:
		pitch_change = sign(p) * pow(abs(p), 2) * 3
		pid_controllers[Controller.PITCH_SPEED].set_target(pitch_change)
		pitch_change += pid_controllers[Controller.PITCH_SPEED].get_output(ang_vel.x, dt, false)
	
	elif flight_mode == FlightMode.LEVEL:
		pid_controllers[Controller.PITCH].set_target(p / 2)
		pitch_change += pid_controllers[Controller.PITCH].get_output(angles.x, dt, false)
	
	elif flight_mode == FlightMode.SPEED:
		pid_controllers[Controller.FORWARD_SPEED].set_target(sign(p) * pow(abs(p), 2) * 5)
		pitch_change = pid_controllers[Controller.FORWARD_SPEED].get_output(
				global_transform.basis.xform_inv(lin_vel).z, dt, false)
		pid_controllers[Controller.PITCH].set_target(clamp(pitch_change, -1, 1) / 2)
		pitch_change += pid_controllers[Controller.PITCH].get_output(angles.x, dt, false)
	
	elif flight_mode == FlightMode.TRACK:
		pid_controllers[Controller.POS_Z].set_target(pid_controllers[Controller.POS_Z].target + p / 100)
		var target = get_tracking_target()
		var delta_z = global_transform.xform_inv(target).z
		var pitch_target = pid_controllers[Controller.POS_Z].get_output(target.z - delta_z, dt) / 2
		pid_controllers[Controller.PITCH].set_target(pitch_target)
		pitch_change += pid_controllers[Controller.PITCH].get_output(angles.x, dt)
	
	elif flight_mode == FlightMode.AUTO:
		pid_controllers[Controller.PITCH].set_target(0)
		pitch_change += pid_controllers[Controller.PITCH].get_output(angles.x, dt, false)
	
	return pitch_change


func change_roll(r):
	var roll_change = 0.0
	
	if flight_mode == FlightMode.RATE:
		roll_change = sign(r) * pow(abs(r), 2) * 3
		pid_controllers[Controller.ROLL_SPEED].set_target(roll_change)
		roll_change += pid_controllers[Controller.ROLL_SPEED].get_output(-ang_vel.z, dt, false)
	
	elif flight_mode == FlightMode.LEVEL:
		pid_controllers[Controller.ROLL].set_target(r / 2)
		roll_change += pid_controllers[Controller.ROLL].get_output(-angles.z, dt)
	
	elif flight_mode == FlightMode.SPEED:
		pid_controllers[Controller.LATERAL_SPEED].set_target(sign(r) * pow(abs(r), 2) * 5)
		roll_change = pid_controllers[Controller.LATERAL_SPEED].get_output(
				global_transform.basis.xform_inv(lin_vel).x, dt, false)
		pid_controllers[Controller.ROLL].set_target(clamp(roll_change, -1, 1) / 2)
		roll_change += pid_controllers[Controller.ROLL].get_output(-angles.z, dt, false)
	
	elif flight_mode == FlightMode.TRACK:
		pid_controllers[Controller.POS_X].set_target(pid_controllers[Controller.POS_X].target + r / 100)
		var target = get_tracking_target()
		var delta_x = global_transform.xform_inv(target).x
		var roll_target = pid_controllers[Controller.POS_X].get_output(target.x - delta_x, dt) / 2
		pid_controllers[Controller.ROLL].set_target(roll_target)
		roll_change += pid_controllers[Controller.ROLL].get_output(-angles.z, dt)
	
	elif flight_mode == FlightMode.AUTO:
		pid_controllers[Controller.ROLL].set_target(0)
		roll_change += pid_controllers[Controller.ROLL].get_output(-angles.z, dt, false)
	
	return roll_change


func change_yaw(y):
	var yaw_change = 0.0
	
	if flight_mode == FlightMode.RATE:
		pid_controllers[Controller.YAW_SPEED].set_target(-sign(y) * pow(abs(y), 2) * 5)
		yaw_change += pid_controllers[Controller.YAW_SPEED].get_output(ang_vel.y, dt, false)
	
	elif flight_mode == FlightMode.LEVEL or flight_mode == FlightMode.SPEED:
		pid_controllers[Controller.YAW_SPEED].set_target(-sign(y) * pow(abs(y), 2) * 2)
		yaw_change += pid_controllers[Controller.YAW_SPEED].get_output(ang_vel.y, dt, false)
	
	elif flight_mode == FlightMode.TRACK:
		var target = pid_controllers[Controller.HEADING].target - y / 100
		while target > PI:
			target -= 2 * PI
		while target < -PI:
			target += 2 * PI
		pid_controllers[Controller.HEADING].set_target(target)
		var hdg_delta = 0
		if abs(target - angles.y) > PI:
			hdg_delta = 2 * PI
			if target < 0:
				hdg_delta = -hdg_delta
		yaw_change += pid_controllers[Controller.HEADING].get_output(angles.y + hdg_delta, dt, true)
	
	elif flight_mode == FlightMode.AUTO:
		pid_controllers[Controller.YAW_SPEED].set_target(0)
		yaw_change += pid_controllers[Controller.YAW_SPEED].get_output(ang_vel.y, dt, false)
	
	return yaw_change
