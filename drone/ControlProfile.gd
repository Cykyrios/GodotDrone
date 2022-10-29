extends Node
class_name ControlProfile


enum Axis {PITCH, ROLL, YAW}
enum RateCurve {ACTUAL, RACEFLIGHT, KISS, QUICKRATES}

var pitch_rate := 667.0
var roll_rate := 667.0
var yaw_rate := 667.0
var pitch_rc := 200.0
var roll_rc := 200.0
var yaw_rc := 200.0
var pitch_expo := 0.2
var roll_expo := 0.2
var yaw_expo := 0.2

var rate_curve := RateCurve.ACTUAL


func get_axis_command(axis: Axis, input: float) -> float:
	input = clampf(input, -1, 1)
	var rate := 0.0
	var rc_rate := 0.0
	var expo := 0.0
	match axis:
		Axis.PITCH:
			rate = pitch_rate
			rc_rate = pitch_rc
			expo = pitch_expo
		Axis.ROLL:
			rate = roll_rate
			rc_rate = roll_rc
			expo = roll_expo
		Axis.YAW:
			rate = yaw_rate
			rc_rate = yaw_rc
			expo = yaw_expo
	var output := get_rate_curve_output(input, rate, rc_rate, expo)
	return output


func get_max_rate(axis: Axis) -> float:
	return get_axis_command(axis, 1.0)


func get_normalized_axis_command(axis: Axis, input: float) -> float:
	return get_axis_command(axis, input) / get_max_rate(axis)


func get_rate_curve_output(input: float, rate: float, rc_rate: float, expo: float) -> float:
	var output := 0.0
	match rate_curve:
		RateCurve.ACTUAL:
			var curve := absf(input) * (pow(input, 5) * expo + input * (1 - expo))
			output = input * rc_rate + maxf(0, rate - rc_rate) * curve
		RateCurve.RACEFLIGHT:
			var curve := (1 + expo * (input * input - 1)) * input
			output = curve * (rate + absf(curve) * rc_rate * rate * 0.01)
		RateCurve.KISS:
			rate /= 100
			rc_rate /= 100
			var command := (pow(input, 3) * expo + input * (1 - expo)) * rc_rate / 10
			output = 2000 / (1 - absf(input) * rate) * command
		RateCurve.QUICKRATES:
			rc_rate = 2 * rc_rate
			rate = maxf(rate, rc_rate)
			var super_expo := (rate / rc_rate - 1) / (rate / rc_rate)
			var curve := pow(absf(input), 3) * expo + absf(input) * (1 - expo)
			output = input * rc_rate / (1 - curve * super_expo)
	return output
