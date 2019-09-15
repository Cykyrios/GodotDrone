extends Control

var altitude = 0.0


func _ready():
	pass # Replace with function body.


func update_altitude(a : float):
	altitude = a
	var alt_sign = " "
	if altitude < 0:
		alt_sign = "-"
	$Label.text = "%s%04d.%d" % [alt_sign, abs(a), (abs(a) - floor(abs(a))) * 10]
