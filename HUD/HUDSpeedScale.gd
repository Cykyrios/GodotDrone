extends Control

var speed = 0.0


func _ready():
	pass # Replace with function body.


func update_speed(s : float):
	speed = s
	$Label.text = "%03d.%d" % [s, (s - floor(s)) * 10]
