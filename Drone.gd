extends RigidBody

class_name Drone

var props
var flight_controller : FlightController

var control_input = 0.0

var climb = 0.0
const CLIMB_RPM = 1000.0
const PROP_LIFT = 0.025

var target_altitude = 0.0


func _ready():
	flight_controller = $FlightController
	props = [$Propeller1, $Propeller2, $Propeller3, $Propeller4]
	flight_controller.set_props(props)


func _process(delta):
	pass


func _physics_process(delta):
	var power = (Input.get_action_strength("increase_power") - Input.get_action_strength("decrease_power") + 1) / 2
	var pitch = Input.get_action_strength("pitch_up") - Input.get_action_strength("pitch_down")
	var roll = Input.get_action_strength("roll_right") - Input.get_action_strength("roll_left")
	var yaw = Input.get_action_strength("yaw_right") - Input.get_action_strength("yaw_left")
	print("Pow: %8.2f ptc: %6.3f rol: %6.3f yaw: %6.3f" % [power, pitch, roll, yaw])
	
	flight_controller.read_position(global_transform.origin, global_transform.basis)
	flight_controller.read_velocity(linear_velocity, angular_velocity)
	flight_controller.read_input(power, pitch, roll, yaw)
	flight_controller.update_control()
	
#	var prop_power = get_flight_controller_output(delta)
	
	
	for prop in props:
#		prop.set_rpm_target(power)
#		prop.set_rpm_target(prop_power)
		var vec_torque = prop.get_torque() * global_transform.basis.y
		var vec_force = prop.global_transform.basis.y * prop.get_thrust()
		var vec_pos = prop.global_transform.origin - global_transform.origin
		add_torque(vec_torque)
		add_force(vec_force, vec_pos)
#	print("%8.3f %8.3f %8.3f %8.3f"
#			% [props[0].get_thrust(), props[1].get_thrust(), props[2].get_thrust(), props[3].get_thrust()])
	print("T: %8.3f RPM: %8.3f L: %8.3f"
			% [props[0].get_torque(), props[0].get_rpm(), props[0].get_thrust()])
	
	add_drag()


func _input(event):
#	if event is InputEventMouseButton and event.is_pressed():
#		if event.button_index == BUTTON_LEFT:
#			target_altitude += 1.0
#		elif event.button_index == BUTTON_RIGHT:
#			target_altitude -= 1.0
#		print(target_altitude)
#
#	# generate control input as Vector3 for desired movement?
#	control_input = target_altitude
	
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == BUTTON_LEFT:
			apply_central_impulse(Vector3.LEFT)
	pass


func get_flight_controller_output(delta):
	flight_controller.read_position(global_transform.origin, global_transform.basis)
	flight_controller.read_velocity(linear_velocity, angular_velocity)
#	flight_controller.read_input(control_input)
	var power = flight_controller.get_power(delta)
	
#	var prop_power = [power, power, power, power]
#	return prop_power
	return power


func add_drag():
	var drag = -linear_velocity.length_squared() * linear_velocity.normalized() / 10.0
	add_central_force(drag)
