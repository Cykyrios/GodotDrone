extends Node

class_name ControlProfile


export (float, 1.0, 1800.0) var rate_pitch = 667.0
export (float, 1.0, 1800.0) var rate_roll = 667.0
export (float, 1.0, 1800.0) var rate_yaw = 667.0

export (float, 0.0, 1.0) var expo_pitch = 0.2
export (float, 0.0, 1.0) var expo_roll = 0.2
export (float, 0.0, 1.0) var expo_yaw = 0.2


func _ready():
	set_rates(rate_pitch, rate_roll, rate_yaw)
	set_expo(expo_pitch, expo_roll, expo_yaw)


func get_rates():
	var rates = [rate_pitch, rate_roll, rate_yaw]
	return rates


func set_rates(p : float, r : float, y : float):
	rate_pitch = p
	rate_roll = r
	rate_yaw = y


func get_expo():
	var expo = [pow(expo_pitch, 3.0), pow(expo_roll, 3.0), pow(expo_yaw, 3.0)]
	return expo


func set_expo(p : float, r : float, y : float):
	expo_pitch = pow(p, 1 / 3.0)
	expo_roll = pow(r, 1 / 3.0)
	expo_yaw = pow(y, 1 / 3.0)
