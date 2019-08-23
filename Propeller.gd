extends Spatial

class_name Propeller

onready var ray = $RayCast
var ray_length = 0.0
var max_ray_length = 0.0

var radius = 0.2

var controller = PID.new()
var thrust_target = 0.0
var torque = 0.0 setget set_torque, get_torque
var rpm = 0.0 setget set_rpm, get_rpm
var rpm_target = 0.0 setget set_rpm_target, get_rpm_target
var max_rpm_change = 0.0

export (bool) var clockwise = false
export (float, 0.0, 10000.0) var MAX_TORQUE = 1000.0
export (float, 0.0, 30000.0) var MAX_RPM = 10000.0
export (float, 0.0, 10.0) var LIFT_RATIO = 1.0
export (float, 0, 50000) var RPM_ACCELERATION = 16000.0


func _ready():
	ray.add_exception(get_parent())
	max_ray_length = ray.cast_to.length()
	
	MAX_TORQUE = MAX_TORQUE / 1000.0
	max_rpm_change = MAX_TORQUE * RPM_ACCELERATION
	
	controller.set_coefficients(1000, 0, 1)
	controller.set_clamp_limits(0, MAX_RPM)


func _physics_process(delta):
	controller.set_target(thrust_target)
	set_rpm_target(controller.get_output(get_thrust(), delta))
	set_rpm(clamp(rpm_target, rpm - max_rpm_change * delta, rpm + max_rpm_change * delta))
	set_torque(rpm / MAX_RPM / delta)
	
	var rot = rpm * PI / 30.0
	if clockwise:
		rot = -rot
	rotate_object_local(Vector3.UP, rot * delta)
	
	transform = transform.orthonormalized()


func set_torque(x : float):
	torque = x


func get_torque():
	if clockwise:
		return torque
	else:
		return -torque


func set_thrust_target(t : float):
	thrust_target = t


func set_rpm_target(x : float):
	rpm_target = x


func get_rpm_target():
	return rpm_target


func set_rpm(x : float):
	rpm = clamp(x, 0.0, MAX_RPM)


func get_rpm():
	return rpm


func get_thrust():
	var rot_speed = rpm * PI / 30.0 * radius
	return (pow(rot_speed, 2) * LIFT_RATIO / 1000) * (1 + 0.3 * get_ground_effect())


func get_ground_effect():
	var ground_effect = 0.0
	if ray.is_colliding():
		ray_length = -global_transform.xform_inv(ray.get_collision_point()).y
		ground_effect = 1 / (1 + pow(ray_length / max_ray_length, 2)) - 0.5
	else:
		ray_length = max_ray_length
#	print("ray: %8.3f gnd: %8.3f" % [ray_length, ground_effect])
	return ground_effect
