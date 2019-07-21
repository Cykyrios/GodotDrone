extends Node

class_name PID

var target setget set_target, get_target
var err = 0.0
var err_prev = 0.0
var integral = 0.0
var freeze_integral = false
var output = 0.0

export (float) var kp = 0.0
export (float) var ki = 0.0
export (float) var kd = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func set_coefficients(p : float, i : float, d : float):
	if p > 0:
		kp = p
	if i > 0:
		ki = i
	if d > 0:
		kd = d


func set_target(t):
	target = t


func get_target():
	return target


func read_input(i):
	target = i


func set_integral_freeze(freeze : bool):
	freeze_integral = freeze


func reset_integral():
	integral = 0.0


func get_output(mv, dt):
	err = target - mv
	if not freeze_integral:
		integral += err * dt
	var deriv = (err - err_prev) / dt
	err_prev = err
	
	var int_term = ki * integral
	output = kp * err + int_term + kd * deriv
	print("target: %8.3f err: %8.3f prop: %8.3f integral: %8.3f deriv: %8.3f total: %8.3f"
			% [target, err, kp * err, ki * integral, kd * deriv, output])
	
	return output
