extends Spatial

class_name FlightController

var dt = 0.0
var pos = Vector3(0, 0, 0)
var pos_prev = pos
var angles = Vector3(0, 0, 0)
var angles_prev = angles
var lin_vel = Vector3(0, 0, 0)
var ang_vel = Vector3(0, 0, 0)

var props = []
var input = [0, 0, 0, 0]

var pid_controllers = []
enum Controller {YAW, ROLL, PITCH, YAW_SPEED, ROLL_SPEED, PITCH_SPEED,
		ALTITUDE, POS_X, POS_Y, VERTICAL_SPEED, X_SPEED, Y_SPEED,
		POWER, RPM, HEADING}

enum FlightMode {RATE, LEVEL, AUTO}
var flight_mode = FlightMode.RATE


func _ready():
	pos = global_transform.origin
	angles = global_transform.basis.get_euler()
	
	for i in range(Controller.size()):
		pid_controllers.append(PID.new())
	
	pid_controllers[Controller.RPM].set_coefficients(1, 0, 0)
	pid_controllers[Controller.RPM].set_clamp_limits(100, 3000)
	
	pid_controllers[Controller.ALTITUDE].set_coefficients(0.2, 0.1, 0.17)
	pid_controllers[Controller.ALTITUDE].set_clamp_limits(0.1, 0.9)
#	pid_controllers[Controller.ALTITUDE].reset_integral(0.2)
	pid_controllers[Controller.VERTICAL_SPEED].set_coefficients(1, 0.1, 0.5)
	pid_controllers[Controller.VERTICAL_SPEED].set_clamp_limits(-2, 2)
	pid_controllers[Controller.ROLL].set_coefficients(0.15, 0.15, 0.05)
	pid_controllers[Controller.ROLL].set_clamp_limits(-0.05, 0.05)
	pid_controllers[Controller.PITCH].set_coefficients(0.15, 0.15, 0.05)
	pid_controllers[Controller.PITCH].set_clamp_limits(-0.05, 0.05)
	
	pid_controllers[Controller.YAW_SPEED].set_coefficients(0.03, 0.0, 0.001)
	pid_controllers[Controller.YAW_SPEED].set_clamp_limits(-1, 1)
	pid_controllers[Controller.ROLL_SPEED].set_coefficients(0.03, 0, 0.001)
	pid_controllers[Controller.ROLL_SPEED].set_clamp_limits(-1, 1)
	pid_controllers[Controller.PITCH_SPEED].set_coefficients(0.03, 0, 0.001)
	pid_controllers[Controller.PITCH_SPEED].set_clamp_limits(-1, 1)


#func _process(delta):
#	pass


func _physics_process(delta):
	dt = delta
	
	pos_prev = pos
	pos = global_transform.origin
	lin_vel = (pos - pos_prev) / dt
	
	angles_prev = angles
	angles = global_transform.basis.get_euler()
	ang_vel = (angles - angles_prev) / dt
	
	print("px %6.2f py %6.2f pz %6.2f, vx %6.2f vy %6.2f vz %6.2f, ax %6.2f ay %6.2f az %6.2f, wx %6.2f wy %6.2f wz %6.2f"
			% [pos.x, pos.y, pos.z, lin_vel.x, lin_vel.y, lin_vel.z,
			angles.x, angles.y, angles.z, ang_vel.x, ang_vel.y, ang_vel.z])
	
	read_input()
	update_control(delta)


func _input(event):
	# used to change modes etc.?
	pass


func get_angles_from_basis():
#	var heading = 0.0
#	var pitch = 0.0
#	var roll = 0.0
	angles = global_transform.basis.get_euler()


func set_props(prop_array):
	props = prop_array


func read_input():
	var power = (Input.get_action_strength("increase_power") - Input.get_action_strength("decrease_power") + 1) / 2
	var pitch = Input.get_action_strength("pitch_up") - Input.get_action_strength("pitch_down")
	var roll = Input.get_action_strength("roll_right") - Input.get_action_strength("roll_left")
	var yaw = Input.get_action_strength("yaw_right") - Input.get_action_strength("yaw_left")
	print("Pow: %8.2f ptc: %6.3f rol: %6.3f yaw: %6.3f" % [power, pitch, roll, yaw])
	input = [power, yaw, roll, pitch]


func update_control(delta):
	dt = delta
	change_power(input[0])
	change_yaw(input[1])
	change_roll(input[2])
	change_pitch(input[3])
	
	for prop in props:
		prop.update_thrust()
#		print("T: %8.3f RPM: %8.3f L: %8.3f"
#				% [prop.get_torque(), prop.get_rpm(), prop.get_thrust()])


func change_power(p):
#	pid_controllers[Controller.ALTITUDE].set_target(3)
#	var power = pid_controllers[Controller.ALTITUDE].get_output(pos.y, dt)
#	for prop in props:
#		prop.set_power(power)
	if flight_mode == FlightMode.RATE:
		for prop in props:
			prop.set_power(p - 0.3)
	
	elif flight_mode == FlightMode.LEVEL:
		var target = pid_controllers[Controller.ALTITUDE].target
		pid_controllers[Controller.ALTITUDE].set_target(target + (p - 0.5) / 20)
		var power = pid_controllers[Controller.ALTITUDE].get_output(pos.y, dt, true)
		for prop in props:
			prop.set_power(power)


func change_pitch(p):
#	var pitch_change = p / 100
#	for i in range(4):
#		if i < 2:
#			props[i].set_power(props[i].get_power() + pitch_change)
#		else:
#			props[i].set_power(props[i].get_power() - pitch_change)
	if flight_mode == FlightMode.RATE:
		var pitch_change = p * 3
		pid_controllers[Controller.PITCH_SPEED].set_target(pitch_change)
		pitch_change = pid_controllers[Controller.PITCH_SPEED].get_output(ang_vel.x, dt, false)
		for i in range(4):
			if i < 2:
				props[i].set_power(props[i].get_power() + pitch_change)
			else:
				props[i].set_power(props[i].get_power() - pitch_change)
	
	elif flight_mode == FlightMode.LEVEL:
		pid_controllers[Controller.PITCH].set_target(p / 4)
		var pitch_change = pid_controllers[Controller.PITCH].get_output(angles.x, dt, true)
		for i in range(4):
			if i < 2:
				props[i].set_power(props[i].get_power() + pitch_change)
			else:
				props[i].set_power(props[i].get_power() - pitch_change)


func change_roll(r):
#	var roll_change = r / 100
#	for i in range(4):
#		if i == 0 or i == 3:
#			props[i].set_power(props[i].get_power() + roll_change)
#		else:
#			props[i].set_power(props[i].get_power() - roll_change)
	if flight_mode == FlightMode.RATE:
		var roll_change = -r * 3
		pid_controllers[Controller.ROLL_SPEED].set_target(roll_change)
		roll_change = pid_controllers[Controller.ROLL_SPEED].get_output(ang_vel.z, dt, false)
		for i in range(4):
			if i == 0 or i == 3:
				props[i].set_power(props[i].get_power() - roll_change)
			else:
				props[i].set_power(props[i].get_power() + roll_change)
	
	elif flight_mode == FlightMode.LEVEL:
		pid_controllers[Controller.ROLL].set_target(r / 4)
		var roll_change = pid_controllers[Controller.ROLL].get_output(-angles.z, dt)
		for i in range(4):
			if i == 0 or i == 3:
				props[i].set_power(props[i].get_power() + roll_change)
			else:
				props[i].set_power(props[i].get_power() - roll_change)


func change_yaw(y):
#	var yaw_change = y / 100
#	for i in range(4):
#		if i == 0 or i == 2:
#			props[i].set_power(props[i].get_power() + yaw_change)
#		else:
#			props[i].set_power(props[i].get_power() - yaw_change)
	var yaw_change = -y * 5
	pid_controllers[Controller.YAW_SPEED].set_target(yaw_change)
	yaw_change = pid_controllers[Controller.YAW_SPEED].get_output(ang_vel.y, dt, false)
	for i in range(4):
		if i == 0 or i == 2:
			props[i].set_power(props[i].get_power() - yaw_change)
		else:
			props[i].set_power(props[i].get_power() + yaw_change)
