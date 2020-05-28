extends Spatial

class_name FlightController

var time = 0.0
var dt = 0.0
var pos = Vector3(0, 0, 0)
var pos_prev = pos
var angles = Vector3(0, 0, 0)
var angles_prev = angles
var lin_vel = Vector3(0, 0, 0)
var local_vel = Vector3(0, 0, 0)
var ang_vel = Vector3(0, 0, 0)
var basis = Basis()
var basis_prev = basis
var basis_flat = basis

var motors = []
var hover_thrust = 0.0
var input = [0, 0, 0, 0]

var control_profile = null


var armed = false setget set_armed


var pid_controllers = []
enum Controller {YAW, ROLL, PITCH, YAW_SPEED, ROLL_SPEED, PITCH_SPEED,
		ALTITUDE, POS_X, POS_Z, VERTICAL_SPEED, FORWARD_SPEED, LATERAL_SPEED,
		LAUNCH}

enum FlightMode {RATE, LEVEL, SPEED, TRACK, LAUNCH, TURTLE, AUTO}
var flight_mode = FlightMode.RATE


export (float, 0.0, 1000.0) var pid_roll_p = 50.0
export (float, 0.0, 1000.0) var pid_roll_i = 30.0
export (float, 0.0, 1000.0) var pid_roll_d = 30.0
export (float, 0.0, 1000.0) var pid_pitch_p = 50.0
export (float, 0.0, 1000.0) var pid_pitch_i = 30.0
export (float, 0.0, 1000.0) var pid_pitch_d = 30.0
export (float, 0.0, 1000.0) var pid_yaw_p = 40.0
export (float, 0.0, 1000.0) var pid_yaw_i = 90.0
export (float, 0.0, 1000.0) var pid_yaw_d = 30.0
var pid_scale_p: float = 0.004
var pid_scale_i: float = 0.002
var pid_scale_d: float = 0.0002


var telemetry_file = File.new()
export (bool) var b_telemetry = false

signal flight_mode_changed

onready var debug_geom = get_tree().root.get_node("Level/DebugGeometry")


func _ready():
#	pos = global_transform.origin
#	basis = global_transform.basis
#	angles = basis.get_euler()
	
	for i in range(Controller.size()):
		pid_controllers.append(PID.new())
		add_child(pid_controllers[-1])
	
	pid_controllers[Controller.ALTITUDE].set_coefficients(80 * pid_scale_p, 100 * pid_scale_i, 1500 * pid_scale_d)
#	pid_controllers[Controller.ALTITUDE].set_clamp_limits(1000.0, 100000.0)
	pid_controllers[Controller.VERTICAL_SPEED].set_coefficients(800 * pid_scale_p, 800 * pid_scale_i, 1500 * pid_scale_d)
#	pid_controllers[Controller.VERTICAL_SPEED].set_clamp_limits(-2, 2)
	pid_controllers[Controller.ROLL].set_coefficients(25 * pid_scale_p, 17 * pid_scale_i, 115 * pid_scale_d)
#	pid_controllers[Controller.ROLL].set_clamp_limits(-0.5, 0.5)
	pid_controllers[Controller.PITCH].set_coefficients(25 * pid_scale_p, 17 * pid_scale_i, 115 * pid_scale_d)
#	pid_controllers[Controller.PITCH].set_clamp_limits(-0.5, 0.5)
	
	pid_controllers[Controller.FORWARD_SPEED].set_coefficients(0.1, 0, 0)
#	pid_controllers[Controller.FORWARD_SPEED].set_clamp_limits(-0.5, 0.5)
	pid_controllers[Controller.LATERAL_SPEED].set_coefficients(0.1, 0, 0)
#	pid_controllers[Controller.LATERAL_SPEED].set_clamp_limits(-0.5, 0.5)
	
	pid_controllers[Controller.YAW_SPEED].set_coefficients(pid_scale_p * pid_yaw_p, pid_scale_i * pid_yaw_i, pid_scale_d * pid_yaw_d)
#	pid_controllers[Controller.YAW_SPEED].set_clamp_limits(-10, 10)
	pid_controllers[Controller.ROLL_SPEED].set_coefficients(pid_scale_p * pid_roll_p, pid_scale_i * pid_roll_i, pid_scale_d * pid_roll_d)
#	pid_controllers[Controller.ROLL_SPEED].set_clamp_limits(-10, 10)
	pid_controllers[Controller.PITCH_SPEED].set_coefficients(pid_scale_p * pid_pitch_p, pid_scale_i * pid_pitch_i, pid_scale_d * pid_pitch_d)
#	pid_controllers[Controller.PITCH_SPEED].set_clamp_limits(-10, 10)
	
	pid_controllers[Controller.POS_X].set_coefficients(0.2, 0.05, 0.2)
#	pid_controllers[Controller.POS_X].set_clamp_limits(-1, 1)
	pid_controllers[Controller.POS_Z].set_coefficients(0.2, 0.05, 0.2)
#	pid_controllers[Controller.POS_Z].set_clamp_limits(-1, 1)
	pid_controllers[Controller.YAW].set_coefficients(25 * pid_scale_p, 8 * pid_scale_i, 165 * pid_scale_d)
#	pid_controllers[Controller.YAW].set_clamp_limits(-1, 1)
	
	pid_controllers[Controller.LAUNCH].set_coefficients(400 * pid_scale_p, 165 * pid_scale_i, 250 * pid_scale_d)
	
	connect("flight_mode_changed", get_parent(), "_on_flight_mode_changed")
	change_flight_mode(FlightMode.RATE)
	
	if b_telemetry:
		var dir = Directory.new()
		dir.remove("user://telemetry.csv")


#func _process(delta):
#	pass


func _physics_process(delta):
	if (flight_mode == FlightMode.LEVEL or flight_mode == FlightMode.SPEED \
			or flight_mode == FlightMode.TRACK) and not is_flight_safe():
		change_flight_mode(FlightMode.AUTO)
	elif flight_mode == FlightMode.LAUNCH and (angles.x < deg2rad(-80) or angles.x > deg2rad(10)):
		_on_disarm_input()

	if flight_mode == FlightMode.TRACK:
		debug_geom.draw_debug_cube(0.02, get_tracking_target(), Vector3(0.2, 0.2, 0.2))

	if b_telemetry:
		write_telemetry()


func set_control_profile(profile : ControlProfile):
	control_profile = profile


func _on_arm_input():
	if input[0] <= 0.01:
		set_armed(true)
		if Input.is_action_pressed("mode_turtle"):
			change_flight_mode(FlightMode.TURTLE)
		elif Input.is_action_pressed("mode_launch"):
			change_flight_mode(FlightMode.LAUNCH)
	for controller in pid_controllers:
		controller.set_disabled(false)


func _on_disarm_input():
	set_armed(false)
	if flight_mode == FlightMode.TURTLE or flight_mode == FlightMode.LAUNCH:
		change_flight_mode(FlightMode.RATE)
	for controller in pid_controllers:
		controller.set_disabled(true)
		controller.reset()


func set_armed(arm : bool):
	armed = arm
	for motor in motors:
		motor.powered = armed


func integrate_loop(delta : float, drone_pos : Vector3, drone_basis : Basis):
	dt = delta
	time += dt
	
	pos_prev = pos
	pos = drone_pos
	
	basis_prev = basis
	basis = drone_basis
	basis_flat = Basis(Vector3(basis.x.x, 0, basis.x.z), Vector3.UP, Vector3(basis.z.x, 0, basis.z.z)).orthonormalized()
	
	angles_prev = angles
	angles = basis.get_euler()
	
	update_velocity()
	
	update_control(dt)


func update_position():
	pos_prev = pos
	pos = global_transform.origin
	
	basis_prev = basis
	basis = global_transform.basis
	
	angles_prev = angles
	angles = basis.get_euler()


func update_velocity():
	lin_vel = (pos - pos_prev) / dt
	local_vel = basis.xform_inv(lin_vel)
	
	var ref1 = Vector3(1, 0, 0)
	var orb1 = basis.xform_inv((pos + basis.xform(ref1) - (pos_prev + basis_prev.xform(ref1))) / dt - lin_vel)
	var omegax = (ref1.cross(orb1) / ref1.length_squared()).cross(ref1)
	var ref2 = Vector3(0, 1, 0)
	var orb2 = basis.xform_inv((pos + basis.xform(ref2) - (pos_prev + basis_prev.xform(ref2))) / dt - lin_vel)
	var omegay = (ref2.cross(orb2) / ref2.length_squared()).cross(ref2)
	var ref3 = Vector3(0, 0, 1)
	var orb3 = basis.xform_inv((pos + basis.xform(ref3) - (pos_prev + basis_prev.xform(ref3))) / dt - lin_vel)
	var omegaz = (ref3.cross(orb3) / ref3.length_squared()).cross(ref3)
	ang_vel = Vector3(omegay.z, omegaz.x, omegax.y)


func init_telemetry():
	telemetry_file.open("user://telemetry.csv", File.WRITE)
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
			"pid.posz.tgt", "pid.posz.err", "pid.posz.out", "pid.posz.clamp"])
	telemetry_file.close()


func write_telemetry():
	if !telemetry_file.file_exists("user://telemetry.csv"):
		init_telemetry()
	
	telemetry_file.open("user://telemetry.csv", File.READ_WRITE)
	telemetry_file.seek_end()
	var data = PoolStringArray([time, input[0], input[1], input[2], input[3],
			pos.x, pos.y, pos.z, lin_vel.x, lin_vel.y, lin_vel.z, local_vel.x, local_vel.y, local_vel.z,
			angles.y, angles.z, angles.x, ang_vel.y, ang_vel.z, ang_vel.x,
			(get_tracking_target() - pos).x, (get_tracking_target() - pos).y, (get_tracking_target() - pos).z,
			motors[0].get_rpm(), motors[1].get_rpm(), motors[2].get_rpm(), motors[3].get_rpm(),
			motors[0].propeller.get_thrust(), motors[1].propeller.get_thrust(), motors[2].propeller.get_thrust(), motors[3].propeller.get_thrust(),
			pid_controllers[Controller.ALTITUDE].target, pid_controllers[Controller.ALTITUDE].err, pid_controllers[Controller.ALTITUDE].output, pid_controllers[Controller.ALTITUDE].clamped_output,
			pid_controllers[Controller.PITCH].target, pid_controllers[Controller.PITCH].err, pid_controllers[Controller.PITCH].output, pid_controllers[Controller.PITCH].clamped_output,
			pid_controllers[Controller.ROLL].target, pid_controllers[Controller.ROLL].err, pid_controllers[Controller.ROLL].output, pid_controllers[Controller.ROLL].clamped_output,
			pid_controllers[Controller.YAW].target, pid_controllers[Controller.YAW].err, pid_controllers[Controller.YAW].output, pid_controllers[Controller.YAW].clamped_output,
			pid_controllers[Controller.YAW_SPEED].target, pid_controllers[Controller.YAW_SPEED].err, pid_controllers[Controller.YAW_SPEED].output, pid_controllers[Controller.YAW_SPEED].clamped_output,
			pid_controllers[Controller.PITCH_SPEED].target, pid_controllers[Controller.PITCH_SPEED].err, pid_controllers[Controller.PITCH_SPEED].output, pid_controllers[Controller.PITCH_SPEED].clamped_output,
			pid_controllers[Controller.ROLL_SPEED].target, pid_controllers[Controller.ROLL_SPEED].err, pid_controllers[Controller.ROLL_SPEED].output, pid_controllers[Controller.ROLL_SPEED].clamped_output,
			pid_controllers[Controller.FORWARD_SPEED].target, pid_controllers[Controller.FORWARD_SPEED].err, pid_controllers[Controller.FORWARD_SPEED].output, pid_controllers[Controller.FORWARD_SPEED].clamped_output,
			pid_controllers[Controller.LATERAL_SPEED].target, pid_controllers[Controller.LATERAL_SPEED].err, pid_controllers[Controller.LATERAL_SPEED].output, pid_controllers[Controller.LATERAL_SPEED].clamped_output,
			pid_controllers[Controller.VERTICAL_SPEED].target, pid_controllers[Controller.VERTICAL_SPEED].err, pid_controllers[Controller.VERTICAL_SPEED].output, pid_controllers[Controller.VERTICAL_SPEED].clamped_output,
			pid_controllers[Controller.POS_X].target, pid_controllers[Controller.POS_X].err, pid_controllers[Controller.POS_X].output, pid_controllers[Controller.POS_X].clamped_output,
			pid_controllers[Controller.POS_Z].target, pid_controllers[Controller.POS_Z].err, pid_controllers[Controller.POS_Z].output, pid_controllers[Controller.POS_Z].clamped_output])
	telemetry_file.store_csv_line(data)
	telemetry_file.close()


func change_flight_mode(mode : int):
	flight_mode = mode
	emit_signal("flight_mode_changed", flight_mode)
	print("Mode: %s" % [flight_mode])


func _on_cycle_flight_modes():
	flight_mode += 1
	while flight_mode == FlightMode.AUTO or flight_mode == FlightMode.TURTLE:
		flight_mode += 1
	if flight_mode >= FlightMode.size():
		flight_mode = 0
	change_flight_mode(flight_mode)
	
	if flight_mode == FlightMode.LEVEL:
		pid_controllers[Controller.ALTITUDE].set_target(pos.y)
	if flight_mode == FlightMode.TRACK:
		pid_controllers[Controller.ALTITUDE].set_target(pos.y)
		pid_controllers[Controller.POS_X].set_target(pos.x)
		pid_controllers[Controller.POS_Z].set_target(pos.z)
		pid_controllers[Controller.YAW].set_target(angles.y)


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


func set_motors(motor_array):
	motors = motor_array


func set_hover_thrust(t : float):
	hover_thrust = t


func set_tracking_target(target : Vector3):
	pid_controllers[Controller.POS_X].set_target(target.x)
	pid_controllers[Controller.ALTITUDE].set_target(target.y)
	pid_controllers[Controller.POS_Z].set_target(target.z)


func get_tracking_target():
	var target = Vector3(pid_controllers[Controller.POS_X].target, pid_controllers[Controller.ALTITUDE].target,
			pid_controllers[Controller.POS_Z].target)
	return target


func update_control(delta):
	dt = delta
	var motor_control = update_command()
#	print("%8.3f %8.3f %8.3f %8.3f" % [power, yaw, roll, pitch])
	
	var power = motor_control[0]
	var yaw = motor_control[1]
	var roll = motor_control[2]
	var pitch = motor_control[3]
	var motor_pwm = [power + yaw + roll + pitch,
			power - yaw - roll + pitch,
			power + yaw - roll - pitch,
			power - yaw + roll - pitch]
	
	# Air Mode
	var pwm_min = motor_pwm.min()
	var pwm_max = motor_pwm.max()
	var idle_pwm = motors[0].MIN_POWER / 100.0
	# Scale PWM to range [idle, 1] as needed
	if pwm_max - pwm_min > 1 - idle_pwm:
		var pwm_mid = (pwm_min + pwm_max) / 2.0
		for i in range(4):
			motor_pwm[i] = pwm_mid + (motor_pwm[i] - pwm_mid) * (1 - idle_pwm) / (pwm_max - pwm_min)
	pwm_min = motor_pwm.min()
	pwm_max = motor_pwm.max()
	var offset = 0.0
	if pwm_min < idle_pwm:
		offset = idle_pwm - pwm_min
	if pwm_max > 1:
		offset = 1 - pwm_max
	for i in range(4):
		motor_pwm[i] += offset
	
	if flight_mode == FlightMode.TURTLE:
		motor_pwm = [0, 0, 0, 0]
		if abs(roll) > abs(pitch):
			if abs(roll) > 0.2:
				if roll > 0:
					motor_pwm[1] = -roll
					motor_pwm[2] = -roll
				else:
					motor_pwm[0] = roll
					motor_pwm[3] = roll
		else:
			if abs(pitch) > 0.2:
				if pitch > 0:
					motor_pwm[2] = -pitch
					motor_pwm[3] = -pitch
				else:
					motor_pwm[0] = pitch
					motor_pwm[1] = pitch
	
	elif flight_mode == FlightMode.LAUNCH:
		motor_pwm = [idle_pwm, idle_pwm, idle_pwm, idle_pwm]
		motor_pwm[2] = clamp(-pitch, idle_pwm, 1)
		motor_pwm[3] = clamp(-pitch, idle_pwm, 1)
		if power > 0.2:
			motor_pwm = [-pitch, -pitch, -pitch, -pitch]
			change_flight_mode(FlightMode.RATE)
	
	motors[0].set_pwm(motor_pwm[0])
	motors[1].set_pwm(motor_pwm[1])
	motors[2].set_pwm(motor_pwm[2])
	motors[3].set_pwm(motor_pwm[3])


func update_command():
	var motor_control = [0, 0, 0, 0]
	
	var pwr = input[0]
	var y = input[1]
	var r = input[2]
	var p = input[3]
	
	var expo_y = control_profile.expo_yaw
	var rate_y = control_profile.rate_yaw
	var expo_r = control_profile.expo_roll
	var rate_r = control_profile.rate_roll
	var expo_p = control_profile.expo_pitch
	var rate_p = control_profile.rate_pitch
	
	if flight_mode == FlightMode.RATE:
		motor_control[0] = pwr
		
		var yaw_input = -((1 - expo_y) * y + expo_y * pow(y, 3)) * deg2rad(rate_y)
		pid_controllers[Controller.YAW_SPEED].set_target(yaw_input)
		motor_control[1] = pid_controllers[Controller.YAW_SPEED].get_output(ang_vel.y, dt, false)
		
		var roll_input = ((1 - expo_r) * r + expo_r * pow(r, 3)) * deg2rad(rate_r)
		pid_controllers[Controller.ROLL_SPEED].set_target(roll_input)
		motor_control[2] = pid_controllers[Controller.ROLL_SPEED].get_output(-ang_vel.z, dt, false)
		
		var pitch_input = ((1 - expo_p) * p + expo_p * pow(p, 3)) * deg2rad(rate_p)
		pid_controllers[Controller.PITCH_SPEED].set_target(pitch_input)
		motor_control[3] = pid_controllers[Controller.PITCH_SPEED].get_output(ang_vel.x, dt, false)
	
	elif flight_mode == FlightMode.LEVEL:
		var bank_limit = deg2rad(35)
		pid_controllers[Controller.VERTICAL_SPEED].set_target((pwr - 0.5) * 10.0)
		motor_control[0] = pid_controllers[Controller.VERTICAL_SPEED].get_output(lin_vel.y, dt, false)
		
		pid_controllers[Controller.YAW_SPEED].set_target(-((1 - expo_y) * y + expo_y * pow(y, 3)) * 2)
		motor_control[1] = pid_controllers[Controller.YAW_SPEED].get_output(ang_vel.y, dt, false)
		
		pid_controllers[Controller.ROLL].set_target(((1 - expo_r) * r + expo_r * pow(r, 3)) * bank_limit)
		motor_control[2] = pid_controllers[Controller.ROLL].get_output(-angles.z, dt)
		
		pid_controllers[Controller.PITCH].set_target(((1 - expo_p) * p + expo_p * pow(p, 3)) * bank_limit)
		motor_control[3] = pid_controllers[Controller.PITCH].get_output(angles.x, dt, false)
	
	elif flight_mode == FlightMode.SPEED:
		var bank_limit = deg2rad(35)
		var flat_vel = basis_flat.xform_inv(lin_vel)
		pid_controllers[Controller.VERTICAL_SPEED].set_target((pwr - 0.5) * 10.0)
		motor_control[0] = pid_controllers[Controller.VERTICAL_SPEED].get_output(lin_vel.y, dt, false)
		
		pid_controllers[Controller.YAW_SPEED].set_target(-((1 - expo_y) * y + expo_y * pow(y, 3)) * 2)
		motor_control[1] = pid_controllers[Controller.YAW_SPEED].get_output(ang_vel.y, dt, false)
		
		pid_controllers[Controller.LATERAL_SPEED].set_target(((1 - expo_r) * r + expo_r * pow(r, 3)) * 10.0)
		var roll_change = pid_controllers[Controller.LATERAL_SPEED].get_output(flat_vel.x, dt, false)
		pid_controllers[Controller.ROLL].set_target(clamp(roll_change, -bank_limit, bank_limit))
		motor_control[2] = pid_controllers[Controller.ROLL].get_output(-angles.z, dt, false)
		
		pid_controllers[Controller.FORWARD_SPEED].set_target(((1 - expo_p) * p + expo_p * pow(p, 3)) * 10.0)
		var pitch_change = pid_controllers[Controller.FORWARD_SPEED].get_output(flat_vel.z, dt, false)
		pid_controllers[Controller.PITCH].set_target(clamp(pitch_change, -bank_limit, bank_limit))
		motor_control[3] = pid_controllers[Controller.PITCH].get_output(angles.x, dt, false)
	
	elif flight_mode == FlightMode.TRACK:
		var target = get_tracking_target()
		var target_prev = target
		target.x = target.x + ((1 - expo_r) * r + expo_r * pow(r, 3)) * 5.0 * dt
		target.y = target.y + (pwr - 0.5) * 5.0 * dt
		target.z = target.z + ((1 - expo_p) * p + expo_p * pow(p, 3)) * 5.0 * dt
		set_tracking_target(target)
		
		motor_control[0] = pid_controllers[Controller.ALTITUDE].get_output(pos.y, dt, false)
		
		target = pid_controllers[Controller.YAW].target - ((1 - expo_y) * y + expo_y * pow(y, 3)) * PI / 2.0 * dt
		while target > PI:
			target -= 2 * PI
		while target < -PI:
			target += 2 * PI
		pid_controllers[Controller.YAW].set_target(target)
		var hdg_delta = 0
		if abs(target - angles.y) > PI:
			hdg_delta = 2 * PI
			if target < 0:
				hdg_delta = -hdg_delta
		motor_control[1] = pid_controllers[Controller.YAW].get_output(angles.y + hdg_delta, dt, false)
		
		var xform = Transform(basis, pos)
		target = get_tracking_target()
		var delta_pos = xform.xform_inv(target)
		var target_vel = (target - target_prev) / dt
		
		var bank_limit = deg2rad(35)
		if lin_vel.length() > 2.8 or target_vel.length() > 2.8 or delta_pos.length() > 3.0:
			pid_controllers[Controller.LATERAL_SPEED].set_target(basis.xform_inv(target_vel).x + 2 * delta_pos.x)
			var roll_change = pid_controllers[Controller.LATERAL_SPEED].get_output(local_vel.x, dt, false)
			pid_controllers[Controller.ROLL].set_target(clamp(roll_change, -bank_limit, bank_limit))
			motor_control[2] = pid_controllers[Controller.ROLL].get_output(-angles.z, dt, false)
			
			pid_controllers[Controller.FORWARD_SPEED].set_target(basis.xform_inv(target_vel).z + 2 * delta_pos.z)
			var pitch_change = pid_controllers[Controller.FORWARD_SPEED].get_output(local_vel.z, dt, false)
			pid_controllers[Controller.PITCH].set_target(clamp(pitch_change, -bank_limit, bank_limit))
			motor_control[3] = pid_controllers[Controller.PITCH].get_output(angles.x, dt, false)
			
		else:
			var roll_target = pid_controllers[Controller.POS_X].get_output(target.x - delta_pos.x, dt)
			pid_controllers[Controller.ROLL].set_target(clamp(roll_target,-bank_limit, bank_limit))
			motor_control[2] = pid_controllers[Controller.ROLL].get_output(-angles.z, dt)
	
			var pitch_target = pid_controllers[Controller.POS_Z].get_output(target.z - delta_pos.z, dt)
			pid_controllers[Controller.PITCH].set_target(clamp(pitch_target,-bank_limit, bank_limit))
			motor_control[3] = pid_controllers[Controller.PITCH].get_output(angles.x, dt)
	
	elif flight_mode == FlightMode.TURTLE:
		motor_control[0] = 0
		motor_control[1] = 0
		if abs(p) > abs(r):
			motor_control[2] = 0
			motor_control[3] = p
		else:
			motor_control[2] = r
			motor_control[3] = 0
	
	elif flight_mode == FlightMode.LAUNCH:
		motor_control[0] = pwr
		
		var pitch_input = pid_controllers[Controller.LAUNCH].target + ((1 - expo_p) * p + expo_p * pow(p, 3)) * dt
		pid_controllers[Controller.LAUNCH].set_target(pitch_input)
		motor_control[3] = pid_controllers[Controller.LAUNCH].get_output(angles.x, dt, false)
	
	elif flight_mode == FlightMode.AUTO:
		pid_controllers[Controller.YAW_SPEED].set_target(0)
		motor_control[1] = pid_controllers[Controller.YAW_SPEED].get_output(ang_vel.y, dt, false)
		
		var bank_limit = deg2rad(20)
		if is_flight_safe():
			var target_speed = -3
			if pos.y < 1:
				set_armed(false)
			pid_controllers[Controller.VERTICAL_SPEED].set_target(target_speed)
			motor_control[0] = pid_controllers[Controller.VERTICAL_SPEED].get_output(lin_vel.y, dt, false)
			
			pid_controllers[Controller.LATERAL_SPEED].set_target(0)
			var roll_change = pid_controllers[Controller.LATERAL_SPEED].get_output(local_vel.x, dt, false)
			pid_controllers[Controller.ROLL].set_target(clamp(roll_change, -bank_limit, bank_limit))
			motor_control[2] = pid_controllers[Controller.ROLL].get_output(-angles.z, dt, false)
			
			pid_controllers[Controller.FORWARD_SPEED].set_target(0)
			var pitch_change = pid_controllers[Controller.FORWARD_SPEED].get_output(local_vel.z, dt, false)
			pid_controllers[Controller.PITCH].set_target(clamp(pitch_change, -bank_limit, bank_limit))
			motor_control[3] = pid_controllers[Controller.PITCH].get_output(angles.x, dt, false)
		
		else:
			if ang_vel.length_squared() <= deg2rad(360):
				pid_controllers[Controller.ROLL].set_target(0)
				motor_control[2] = pid_controllers[Controller.ROLL].get_output(-angles.z, dt, false)
				pid_controllers[Controller.PITCH].set_target(0)
				motor_control[3] = pid_controllers[Controller.PITCH].get_output(angles.x, dt, false)
			else:
				pid_controllers[Controller.ROLL_SPEED].set_target(0)
				motor_control[2] = pid_controllers[Controller.ROLL_SPEED].get_output(-ang_vel.z, dt, false)
				pid_controllers[Controller.PITCH_SPEED].set_target(0)
				motor_control[3] = pid_controllers[Controller.PITCH_SPEED].get_output(ang_vel.x, dt, false)
	
	return motor_control


func reset():
	set_armed(false)
	
	# Update position twice to ensure pos_prev == pos
	for i in range(2):
		update_position()
	update_velocity()
	
	for controller in pid_controllers:
		controller.reset()
	pid_controllers[Controller.ALTITUDE].target = pos.y
	pid_controllers[Controller.POS_X].target = pos.x
	pid_controllers[Controller.POS_Z].target = pos.z
	
	for motor in motors:
		motor.set_rpm(0)
