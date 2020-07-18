extends "res://GUI/GUIControllerAxis.gd"
class_name GUIControllerButton


func _ready() -> void:
	._ready()
	.set_range(0, 1, 1)
	color_on = Color(0.8, 0.0, 0.0, 1.0)
	.set_color_on(color_on, true)
