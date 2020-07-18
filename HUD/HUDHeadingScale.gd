extends Control


onready var heading_label := $VBoxContainer/Label
onready var heading_gauge := $VBoxContainer/HeadingGauge

var heading := 0.0
var heading_prev := 0.0


func update_heading(hdg: float, dt: float) -> void:
	heading_prev = heading
	heading = hdg
	var polar_hdg := -heading * 180 / PI
	if polar_hdg < 0:
		polar_hdg += 360
	heading_label.text = "%03d" % polar_hdg
	
	var heading_delta := 0.0
	if dt != 0:
		var overflow_fix := 0.0
		if abs(heading - heading_prev) > PI:
			overflow_fix = 2 * PI * sign(heading)
		heading_delta = -(heading - heading_prev - overflow_fix) / dt
	heading_gauge.update_gauge(heading_delta)
