class_name GUIControllerAxis
extends TextureProgressBar


var texture_path := "res://Assets/GUI/ControlAxes.png"

var color_on := Color(1.0, 0.6, 0.0, 1.0)
var color_off := color_on * 0.25

func _ready() -> void:
	custom_minimum_size = Vector2i(200, 12)
	set_range(-1.0, 1.0, 0.01)
	value = 0.0
	nine_patch_stretch = true
	stretch_margin_top = 3
	stretch_margin_bottom = 3
	stretch_margin_left = 3
	stretch_margin_right = 3
	texture_progress = load(texture_path)
	tint_progress = color_on
	texture_under = texture_progress
	tint_under = color_off
	tint_under.a = 1.0


func set_range(vmin: float, vmax: float, vstep: float) -> void:
	min_value = vmin
	max_value = vmax
	step = vstep
	value = clampf(value, min_value, max_value)


func set_color_on(color: Color, update_color_off: bool) -> void:
	color_on = color
	tint_progress = color_on
	if update_color_off:
		reset_color_off()


func set_color_off(color: Color) -> void:
	color_off = color
	tint_under = color_off


func reset_color_off() -> void:
	if color_on.r >= 0.5 or color_on.g >= 0.5 or color_on.b >= 0.5:
		color_off = color_on * 0.25
	else:
		color_off = color_on * 2.0
	color_off.a = 1.0
	tint_under = color_off
