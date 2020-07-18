extends Node
class_name PID


var target := 0.0 setget set_target, get_target
var err := 0.0
var err_prev := 0.0
var mv_prev := 0.0
var proportional := 0.0
var integral := 0.0
var windup := false
var derivative := 0.0
var tau := 0.01
var output := 0.0

var clamp_low: float = -INF
var clamp_high: float = INF
var clamped_output := 0.0
var saturated := false

var disabled := false setget set_disabled

export (float) var kp := 0.0
export (float) var ki := 0.0
export (float) var kd := 0.0


func set_disabled(d: bool) -> void:
	disabled = d


func set_coefficients(p: float, i: float, d: float) -> void:
	if p > 0:
		kp = p
	if i > 0:
		ki = i
	if d > 0:
		kd = d


func set_target(t: float) -> void:
	target = t


func get_target() -> float:
	return target


func set_clamp_limits(low: float, high: float) -> void:
	clamp_low = low
	clamp_high = high


func set_derivative_filter_tau(t: float = 0.01) -> void:
	tau = abs(t)


func set_derivative_filter_frequency(f: float = 16.0) -> void:
	# Default frequency of 16 Hz corresponds to tau = 0.01
	if f > 0:
		tau = 1 / (2 * PI * f)


func reset() -> void:
	set_target(0.0)
	err = 0.0
	err_prev = 0.0
	mv_prev = 0.0
	reset_integral()
	saturated = false
	derivative = 0.0
	output = 0.0
	clamped_output = 0.0


func reset_integral(i: float = 0.0) -> void:
	integral = i


func get_output(mv: float, dt: float, p_print: bool = false) -> float:
	if disabled:
		return 0.0
	
	err = target - mv
	
	proportional = kp * err
	
	integral += 0.5 * ki * dt * (err + err_prev)
	var integral_max := max(clamp_high - proportional, 0)
	var integral_min := min(clamp_low - proportional, 0)
	if integral <= integral_min or integral >= integral_max:
		windup = true
	else:
		windup = false
	integral = clamp(integral, integral_min, integral_max)
	
	# Derivative on measurement: opposite sign from derivative on error
	# Low-pass filter on derivative
	derivative = (2 * kd * (mv_prev - mv) + (2 * tau - dt) * derivative) / (2 * tau + dt)
	
	err_prev = err
	mv_prev = mv
	
	output = proportional + integral + derivative
	clamped_output = clamp(output, clamp_low, clamp_high)
	if abs(output) >= abs(clamped_output):
		saturated = true
	else:
		saturated = false
	if p_print:
		print("target: %8.3f err: %8.3f prop: %8.3f integral: %8.3f deriv: %8.3f total: %8.3f clamped: %8.3f windup: %s"
				% [target, err, proportional, integral, derivative, output, clamped_output, windup])
	
	return clamped_output
