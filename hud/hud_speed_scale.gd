class_name HUDSpeedScale
extends Control


@onready var speed_label := %Label as Label
@onready var speed_gauge := %SpeedGauge as HUDBidirectionalGauge

var speed := 0.0
var speed_prev := 0.0


func update_speed(new_speed: float, dt: float) -> void:
	speed_prev = speed
	speed = new_speed
	speed_label.text = "%03d" % [speed * 3.6]

	var speed_delta := 0.0
	if dt != 0:
		speed_delta = (speed - speed_prev) / dt
	speed_gauge.update_gauge(speed_delta)
