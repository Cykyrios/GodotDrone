extends Node

class_name PID

var target = 0.0 setget set_target, get_target
var err = 0.0
var err_prev = 0.0
var integral = 0.0
var freeze_integral = false
var output = 0.0

var clamp_low = -INF
var clamp_high = INF
var clamped_output = 0.0

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


func set_clamp_limits(low, high):
	clamp_low = low
	clamp_high = high


func is_saturated():
	var saturated = false
	if clamped_output != output and sign(output) == sign(err):
		saturated = true
	return saturated


func reset_integral(i = 0.0):
	integral = i


func get_output(mv, dt, p_print = false):
	err = target - mv
	if not is_saturated():
		integral += err * dt
	var deriv = (err - err_prev) / dt
	err_prev = err
	
	output = kp * err + ki * integral + kd * deriv
	clamped_output = clamp(output, clamp_low, clamp_high)
	if p_print:
		print("target: %8.3f err: %8.3f prop: %8.3f integral: %8.3f deriv: %8.3f total: %8.3f clamped: %8.3f"
				% [target, err, kp * err, ki * integral, kd * deriv, output, clamped_output])
	
	return clamped_output
