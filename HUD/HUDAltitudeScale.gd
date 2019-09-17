extends Control

onready var altitude_label = $HBoxContainer/Label
onready var altitude_gauge = $HBoxContainer/AltitudeGauge

var altitude = 0.0
var altitude_prev = 0.0


func _ready():
	pass # Replace with function body.


func update_altitude(a : float, dt : float):
	altitude_prev = altitude
	altitude = a
	var alt_sign = " "
	if altitude < 0:
		alt_sign = "-"
	altitude_label.text = "%s%04d.%d" % [alt_sign, abs(a), (abs(a) - floor(abs(a))) * 10]
	
	var altitude_delta = 0.0
	if dt != 0:
		altitude_delta = (altitude - altitude_prev) / dt
	altitude_gauge.update_gauge(altitude_delta)
