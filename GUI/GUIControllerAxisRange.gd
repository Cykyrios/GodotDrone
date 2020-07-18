extends Container
class_name GUIControllerAxisRange


var axis_monitor := GUIControllerAxis.new()
var axis_range := TextureProgress.new()
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
	
	axis_range.rect_size = axis_monitor.rect_min_size
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
	
	var axis_size := axis_monitor.rect_min_size
	button_low.rect_min_size = Vector2(20, axis_size.y + 20)
	var button_low_pos := (axis_size - button_low.rect_min_size + bound_low * Vector2(axis_size.x, 0)) / 2
	button_low.rect_position = button_low_pos
	button_high.rect_min_size = Vector2(20, axis_size.y + 20)
	var button_high_pos := (axis_size - button_high.rect_min_size + bound_high * Vector2(axis_size.x, 0)) / 2
	button_high.rect_position = button_high_pos
	button_low.focus_mode = Control.FOCUS_NONE
	button_high.focus_mode = Control.FOCUS_NONE
	
	call_deferred("update_pos")
	
	var _discard = button_low.connect("button_down", self, "_on_button_pressed", [1])
	_discard = button_high.connect("button_down", self, "_on_button_pressed", [2])
	_discard = button_low.connect("button_up", self, "_on_button_released")
	_discard = button_high.connect("button_up", self, "_on_button_released")
	
	call_deferred("update_bounds")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and dragging > 0:
		var delta := (event as InputEventMouseMotion).relative.x
		var axis_size := axis_monitor.rect_size
		if dragging == 1:
			var button_pos := button_low.rect_position
			var button_size := button_low.rect_size
			var xmin := -button_size.x / 2
			var xmax := button_high.rect_position.x - button_size.x
			var posx := clamp(button_pos.x + delta, xmin, xmax - 1)
			button_low.rect_position = Vector2(posx, button_pos.y)
		elif dragging == 2:
			var button_pos := button_high.rect_position
			var button_size := button_high.rect_size
			var xmin := button_low.rect_position.x + button_low.rect_size.x
			var xmax := axis_size.x - button_size.x / 2
			var posx := clamp(button_pos.x + delta, xmin + 1, xmax)
			button_high.rect_position = Vector2(posx, button_pos.y)
		update_bounds()


func update_pos() -> void:
	rect_min_size.y = button_high.rect_size.y
	size_flags_vertical = SIZE_EXPAND
	grow_vertical = Control.GROW_DIRECTION_BOTH
	rect_position = rect_size / 2
	for child in get_children():
		child.rect_position.y = (rect_size - child.rect_size).y / 2


func update_bounds() -> void:
	bound_low = (button_low.rect_position.x + button_low.rect_size.x / 2) / axis_monitor.rect_size.x * 2 - 1
	bound_high = (button_high.rect_position.x + button_high.rect_size.x / 2) / axis_monitor.rect_size.x * 2 - 1
	axis_range.rect_size.x = button_high.rect_position.x - button_low.rect_position.x
	axis_range.rect_position.x = button_low.rect_position.x + button_low.rect_size.x / 2
	emit_signal("range_updated")


func set_bounds(low: float, high: float) -> void:
	button_low.rect_position.x = (low + 1) * axis_monitor.rect_size.x / 2 - button_low.rect_size.x / 2
	button_high.rect_position.x = (high + 1) * axis_monitor.rect_size.x / 2 - button_high.rect_size.x / 2
	update_bounds()


func _on_button_pressed(id: int) -> void:
	dragging = id


func _on_button_released() -> void:
	dragging = 0
	emit_signal("range_released")
