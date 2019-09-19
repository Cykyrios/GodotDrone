extends Control

onready var altitude_label = $HBoxContainer/VBoxContainer/LabelAltitude
onready var radioaltitude_label = $HBoxContainer/VBoxContainer/LabelRadioAltitude
onready var vertical_speed_label = $HBoxContainer/VBoxContainer/LabelVerticalSpeed
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
	
	var vertical_speed = 0.0
	if dt != 0:
		vertical_speed = (altitude - altitude_prev) / dt
	altitude_gauge.update_gauge(vertical_speed)
	var vs_sign = " "
	if vertical_speed < 0:
		vs_sign = "-"
	vertical_speed_label.text = "%s%02d.%d" % [vs_sign, abs(vertical_speed),
			(abs(vertical_speed) - floor(abs(vertical_speed))) * 10]


func update_radio_altitude(a : float):
	if a > 10 or a < 0:
		radioaltitude_label.text = "R---"
	else:
		radioaltitude_label.text = "R%02d.%d" % [a, (a - floor(a)) * 10]
