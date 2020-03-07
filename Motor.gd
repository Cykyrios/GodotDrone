tool
extends Spatial

class_name Motor


onready var propeller = get_children().back() as Propeller

export (bool) var clockwise = true setget set_clockwise
export (float, 0.0, 10000.0) var MAX_TORQUE = 1000.0
export (float, 0.0, 30000.0) var MAX_RPM = 10000.0
export (float, 0, 50000) var RPM_ACCELERATION = 16000.0
export (int, 0, 100) var MIN_POWER = 1
export (int, 100, 20000) var kv = 2000
export (int, 101, 9999) var motor_size = 2207

var controller = PID.new()
var thrust_target = 0.0
var torque = 0.0 setget set_torque, get_torque
var rpm = 0.0 setget set_rpm, get_rpm
var rpm_target = 0.0 setget set_rpm_target, get_rpm_target
var max_rpm_change = 0.0
var powered = true


func _enter_tree():
	set_clockwise(clockwise)


func _ready():
	if Engine.editor_hint:
		return
	
	MAX_TORQUE = MAX_TORQUE / 1000.0
	max_rpm_change = MAX_TORQUE * RPM_ACCELERATION
	
	controller.set_coefficients(1000, 0, 1)
	controller.set_clamp_limits(MIN_POWER / 100.0 * MAX_RPM, MAX_RPM)


func _physics_process(delta):
	if Engine.editor_hint:
		return


func update_thrust(delta):
	if powered:
		controller.set_target(thrust_target)
		set_rpm_target(controller.get_output(propeller.get_thrust(), delta))
		set_rpm(clamp(rpm_target, rpm - max_rpm_change * delta, rpm + max_rpm_change * delta))
	else:
		set_rpm(clamp(0, rpm - max_rpm_change * delta, rpm + max_rpm_change * delta))
	set_torque(rpm / MAX_RPM / delta)


func set_clockwise(cw : bool):
	clockwise = cw
	for node in get_children():
		if node is Propeller:
			node.set_clockwise(clockwise)


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
	propeller.rpm = rpm


func get_rpm():
	return rpm
