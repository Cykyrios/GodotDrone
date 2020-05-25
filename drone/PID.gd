extends Node

class_name PID

var target = 0.0 setget set_target, get_target
var err = 0.0
var err_prev = 0.0
var mv_prev = 0.0
var integral = 0.0
var freeze_integral = false
var derivative = 0.0
var tau = 0.01
var output = 0.0

var clamp_low = -INF
var clamp_high = INF
var clamped_output = 0.0

var disabled = false setget set_disabled

export (float) var kp = 0.0
export (float) var ki = 0.0
export (float) var kd = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func set_disabled(d : bool):
	disabled = d


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


func set_derivative_filter_tau(t = 0.01):
	tau = abs(t)


func set_derivative_filter_frequency(f = 16.0):
	# Default frequency of 16 Hz corresponds to tau = 0.01
	if f > 0:
		tau = 1 / (2 * PI * f)


func is_saturated():
	var saturated = false
	if abs(clamped_output - output) > 0.00001 and sign(output) == sign(err_prev):
		saturated = true
	return saturated


func reset():
	set_target(0.0)
	err = 0.0
	err_prev = 0.0
	mv_prev = 0.0
	reset_integral()
	freeze_integral = false
	derivative = 0.0
	output = 0.0
	clamped_output = 0.0


func reset_integral(i = 0.0):
	integral = i


func get_output(mv, dt, p_print = false):
	if disabled:
		return 0.0
	
	err = target - mv
	
	var proportional = kp * err
	
	if not is_saturated():
		integral += 0.5 * ki * dt * (err + err_prev)
	
	# Derivative on measurement: opposite sign from derivative on error
	# Low-pass filter on derivative
	derivative = (2 * kd * (mv_prev - mv) + (2 * tau - dt) * derivative) / (2 * tau + dt)
	
	err_prev = err
	mv_prev = mv
	
	output = proportional + integral + derivative
	clamped_output = clamp(output, clamp_low, clamp_high)
	if p_print:
		print("target: %8.3f err: %8.3f prop: %8.3f integral: %8.3f deriv: %8.3f total: %8.3f clamped: %8.3f sat: %s"
				% [target, err, proportional, integral, derivative, output, clamped_output, is_saturated()])
	
	return clamped_output
