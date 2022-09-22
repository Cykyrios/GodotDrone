extends Control


@onready var speed_label := $HBoxContainer/Label
@onready var speed_gauge := $HBoxContainer/SpeedGauge

var speed := 0.0
var speed_prev := 0.0


func update_speed(s: float, dt: float) -> void:
	speed_prev = speed
	speed = s
	speed_label.text = "%03d" % [s * 3.6]
	
	var speed_delta := 0.0
	if dt != 0:
		speed_delta = (speed - speed_prev) / dt
	speed_gauge.update_gauge(speed_delta)
