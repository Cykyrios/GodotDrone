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

var torque = 0.0 setget set_torque, get_torque
var rpm = 0.0 setget set_rpm, get_rpm
var rpm_target = 0.0 setget set_rpm_target, get_rpm_target
var max_rpm_change = 0.0
var powered = false

onready var rotor = $Motor_Rotor


func _ready():
	set_clockwise(clockwise)
	
	if Engine.editor_hint:
		return
	
	MAX_TORQUE = MAX_TORQUE / 1000.0
	max_rpm_change = MAX_TORQUE * RPM_ACCELERATION


func _process(delta):
	if Engine.editor_hint:
		return
	
	var rot = rpm * PI / 30.0
	if clockwise:
		rot = -rot
	rotor.rotate_object_local(Vector3.UP, rot * delta)
	propeller.rotate_object_local(Vector3.UP, rot * delta)
	
	rotor.transform = rotor.transform.orthonormalized()
	propeller.transform = propeller.transform.orthonormalized()


func update_thrust(delta):
	if powered:
		set_rpm(clamp(rpm_target, rpm - max_rpm_change * delta, rpm + max_rpm_change * delta))
		set_torque(rpm / (MAX_RPM as float) * MAX_TORQUE)
	else:
		set_rpm(clamp(0, rpm - max_rpm_change * delta, rpm + max_rpm_change * delta))
		set_torque(0.0)


func set_clockwise(cw : bool):
	clockwise = cw
	if propeller:
		propeller.set_clockwise(clockwise)


func set_torque(x : float):
	torque = x


func get_torque():
	if clockwise:
		return torque
	else:
		return -torque


func set_rpm_target(x : float):
	rpm_target = x


func get_rpm_target():
	return rpm_target


func set_rpm(x : float):
	rpm = clamp(x, 0.0, MAX_RPM)
	propeller.rpm = rpm


func get_rpm():
	return rpm
