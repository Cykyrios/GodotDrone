class_name HUDAltitudeScale
extends Control


@onready var altitude_label := %LabelAltitude as Label
@onready var radioaltitude_label := %LabelRadioAltitude as Label
@onready var vertical_speed_label := %LabelVerticalSpeed as Label
@onready var altitude_gauge := %AltitudeGauge as HUDBidirectionalGauge

var altitude := 0.0
var altitude_prev := 0.0


func update_altitude(new_altitude: float, dt: float) -> void:
	altitude_prev = altitude
	altitude = new_altitude
	var alt_sign := " "
	if altitude < 0:
		alt_sign = "-"
	altitude_label.text = "%s%04d.%d" % [alt_sign, absf(new_altitude),
			(absf(new_altitude) - floori(absf(new_altitude))) * 10]

	var vertical_speed := 0.0
	if dt != 0:
		vertical_speed = (altitude - altitude_prev) / dt
	altitude_gauge.update_gauge(vertical_speed)
	var vs_sign := "-" if vertical_speed < 0 else " "
	vertical_speed_label.text = "%s%02d.%d VS" % [vs_sign, absf(vertical_speed),
			(absf(vertical_speed) - floori(absf(vertical_speed))) * 10]


func update_radio_altitude(new_altitude: float) -> void:
	if new_altitude > 10 or new_altitude < 0:
		radioaltitude_label.text = "R---"
	else:
		radioaltitude_label.text = "R%02d.%d" % [new_altitude,
				(new_altitude - floori(new_altitude)) * 10]
