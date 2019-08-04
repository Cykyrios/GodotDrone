extends Spatial

class_name FlightController

var dt = 0.0
var pos = Vector3(0, 0, 0)
var pos_prev = pos
var basis
var angles = Vector3(0, 0, 0)
var angles_prev = angles
var lin_vel = Vector3(0, 0, 0)
var ang_vel = Vector3(0, 0, 0)

var props = []
var input = [0, 0, 0, 0]

var pid_controllers = []


func _ready():
	pos = global_transform.origin
	basis = global_transform.basis
	
	for i in range(3):
		pid_controllers.append(PID.new())
		pid_controllers[-1].set_coefficients(0.1, 0, 0.01)


#func _process(delta):
#	pass


func _physics_process(delta):
	dt = delta
	
	pos_prev = pos
	pos = global_transform.origin
	lin_vel = (global_transform.origin - pos / dt)
	
	angles_prev = angles
	basis = global_transform.basis
	
	read_input()
	update_control(delta)


func _input(event):
	# used to change modes etc.?
	pass


func get_angles_from_basis():
	var heading = 0.0
	var pitch = 0.0
	var roll = 0.0


func set_props(prop_array):
	props = prop_array


func read_position(p : Vector3, a : Vector3):
	pos = p
	angles = a
	print("pitch: %6.3f yaw: %6.3f roll: %6.3f" % [angles.x, angles.y, angles.z])


func read_velocity(lin_v : Vector3, ang_v : Vector3):
	lin_vel = lin_v
	ang_vel = ang_v
	print("pitch: %6.3f yaw: %6.3f roll: %6.3f" % [ang_vel.x, ang_vel.y, ang_vel.z])


func read_input():
	var power = (Input.get_action_strength("increase_power") - Input.get_action_strength("decrease_power") + 1) / 2
	var pitch = Input.get_action_strength("pitch_up") - Input.get_action_strength("pitch_down")
	var roll = Input.get_action_strength("roll_right") - Input.get_action_strength("roll_left")
	var yaw = Input.get_action_strength("yaw_right") - Input.get_action_strength("yaw_left")
	print("Pow: %8.2f ptc: %6.3f rol: %6.3f yaw: %6.3f" % [power, pitch, roll, yaw])
	input = [power, pitch, roll, yaw]


func update_control(delta):
	dt = delta
	change_power(input[0])
	change_pitch(input[1])
	change_roll(input[2])
	change_yaw(input[3])
	
	for prop in props:
		prop.update_thrust()
		print("T: %8.3f RPM: %8.3f L: %8.3f"
				% [prop.get_torque(), prop.get_rpm(), prop.get_thrust()])


func change_power(p):
	for prop in props:
		prop.set_power(p - 0.3)


func change_pitch(p):
	var pitch_change = p / 100
#	pid_controllers[0].set_target(pitch_change * dt)
#	pitch_change = pid_controllers[0].get_output(ang_vel.x, dt)
#	print(ang_vel, "vel: %8.3f target: %8.3f pid: %8.3f" % [ang_vel.x, pid_controllers[0].get_target(), pitch_change])
	for i in range(4):
		if i < 2:
			props[i].set_power(props[i].get_power() + pitch_change)
		else:
			props[i].set_power(props[i].get_power() - pitch_change)


func change_roll(r):
	var roll_change = r / 100
	for i in range(4):
		if i == 0 or i == 3:
			props[i].set_power(props[i].get_power() + roll_change)
		else:
			props[i].set_power(props[i].get_power() - roll_change)


func change_yaw(y):
	var yaw_change = y / 100
#	pid_controllers[0].set_target(yaw_change * dt)
#	yaw_change = pid_controllers[0].get_output(ang_vel.y, dt)
#	print(ang_vel, "vel: %8.3f target: %8.3f pid: %8.3f" % [ang_vel.y, pid_controllers[0].get_target(), yaw_change])
	for i in range(4):
		if i == 0 or i == 2:
			props[i].set_power(props[i].get_power() + yaw_change)
		else:
			props[i].set_power(props[i].get_power() - yaw_change)
