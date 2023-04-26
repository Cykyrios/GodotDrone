class_name GUIControllerButton
extends GUIControllerAxis


func _ready() -> void:
	super()
	super.set_range(0, 1, 1)
	color_on = Color(0.8, 0.0, 0.0, 1.0)
	super.set_color_on(color_on, true)
