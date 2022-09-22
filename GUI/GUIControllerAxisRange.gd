extends Container
class_name GUIControllerAxisRange


var axis_monitor := GUIControllerAxis.new()
var axis_range := TextureProgressBar.new()
var button_low := Button.new()
var button_high := Button.new()
var bound_low := 0.0
var bound_high := 1.0

var dragging := 0
var mouse_pos_prev := Vector2.ZERO

signal range_updated
signal range_released


func _ready() -> void:
	add_child(axis_monitor)
	add_child(axis_range)
	add_child(button_low)
	add_child(button_high)

	axis_range.size = axis_monitor.minimum_size
	axis_range.texture_progress = load("res://Assets/GUI/ControlAxes_Transparent.png")
	axis_range.nine_patch_stretch = true
	axis_range.stretch_margin_top = 3
	axis_range.stretch_margin_bottom = 3
	axis_range.stretch_margin_left = 3
	axis_range.stretch_margin_right = 3
	axis_range.min_value = 0
	axis_range.max_value = 1
	axis_range.step = 0.1
	axis_range.value = 1

	var axis_size: Vector2 = axis_monitor.custom_minimum_size as Vector2
	button_low.minimum_size = Vector2(20, axis_size.y + 20)
	var button_low_pos := (axis_size - (button_low.custom_minimum_size as Vector2) \
			+ bound_low * Vector2(axis_size.x, 0)) / 2
	button_low.position = button_low_pos
	button_high.minimum_size = Vector2(20, axis_size.y + 20)
	var button_high_pos := (axis_size - (button_high.custom_minimum_size as Vector2) \
			+ bound_high * Vector2(axis_size.x, 0)) / 2
	button_high.position = button_high_pos
	button_low.focus_mode = Control.FOCUS_NONE
	button_high.focus_mode = Control.FOCUS_NONE

	call_deferred("update_pos")

	var _discard = button_low.button_down.connect(_on_button_pressed.bind(1))
	_discard = button_high.button_down.connect(_on_button_pressed.bind(2))
	_discard = button_low.button_up.connect(_on_button_released)
	_discard = button_high.button_up.connect(_on_button_released)

	call_deferred("update_bounds")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and dragging > 0:
		var delta := (event as InputEventMouseMotion).relative.x
		var axis_size := axis_monitor.size
		if dragging == 1:
			var button_pos := button_low.position
			var button_size := button_low.size
			var xmin := -button_size.x / 2
			var xmax := button_high.position.x - button_size.x
			var posx := clampf(button_pos.x + delta, xmin, xmax - 1)
			button_low.position = Vector2(posx, button_pos.y)
		elif dragging == 2:
			var button_pos := button_high.position
			var button_size := button_high.size
			var xmin := button_low.position.x + button_low.size.x
			var xmax := axis_size.x - button_size.x / 2
			var posx := clampf(button_pos.x + delta, xmin + 1, xmax)
			button_high.position = Vector2(posx, button_pos.y)
		update_bounds()


func update_pos() -> void:
	custom_minimum_size.y = button_high.size.y
	size_flags_vertical = SIZE_EXPAND
	grow_vertical = Control.GROW_DIRECTION_BOTH
	position = size / 2
	for child in get_children():
		child.position.y = (size - child.size).y / 2


func update_bounds() -> void:
	bound_low = (button_low.position.x + button_low.size.x / 2) / axis_monitor.size.x * 2 - 1
	bound_high = (button_high.position.x + button_high.size.x / 2) / axis_monitor.size.x * 2 - 1
	axis_range.size.x = button_high.position.x - button_low.position.x
	axis_range.position.x = button_low.position.x + button_low.size.x / 2
	range_updated.emit()


func set_bounds(low: float, high: float) -> void:
	button_low.position.x = (low + 1) * axis_monitor.size.x / 2 - button_low.size.x / 2
	button_high.position.x = (high + 1) * axis_monitor.size.x / 2 - button_high.size.x / 2
	update_bounds()


func _on_button_pressed(id: int) -> void:
	dragging = id


func _on_button_released() -> void:
	dragging = 0
	range_released.emit()
