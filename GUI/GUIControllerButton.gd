class_name GUIControllerButton
extends "res://GUI/GUIControllerAxis.gd"


func _ready() -> void:
	super._ready()
	super.set_range(0, 1, 1)
	color_on = Color(0.8, 0.0, 0.0, 1.0)
	super.set_color_on(color_on, true)
