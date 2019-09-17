extends Control

onready var speed_label = $HBoxContainer/Label
onready var speed_gauge = $HBoxContainer/SpeedGauge

var speed = 0.0
var speed_prev = 0.0


func _ready():
	pass # Replace with function body.


func update_speed(s : float, dt : float):
	speed_prev = speed
	speed = s
	speed_label.text = "%03d.%d" % [s, (s - floor(s)) * 10]
	
	var speed_delta = 0.0
	if dt != 0:
		speed_delta = (speed - speed_prev) / dt
	speed_gauge.update_gauge(speed_delta)
