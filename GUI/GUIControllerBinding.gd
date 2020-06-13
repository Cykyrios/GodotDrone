extends VBoxContainer
class_name GUIControllerBinding


var dict_idx = -1
var action = ""
var label = Label.new()
var controller_button = GUIControllerButton.new()
var axis_range = null
var device = -1
var button = -1
var axis = -1
var axis_value = 0.0

var highlight = false
var t = 0.0
var pressed = false

signal clicked
signal binding_updated


func _ready():
	add_child(label)
	add_child(controller_button)
	label.add_font_override("font", load("res://GUI/BindingsFont.tres"))
	controller_button.size_flags_horizontal = 0
	controller_button.size_flags_vertical = SIZE_SHRINK_CENTER
	controller_button.rect_min_size = Vector2(controller_button.rect_min_size.x, 16)
	controller_button.set_range(0, 1, 1)
	controller_button.value = 0
	controller_button.set_color_on(Color(0.8, 0.0, 0.0, 1.0), true)
	
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	controller_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")


func _process(delta):
	if highlight:
		t += delta
		var col1 = cos(2 * PI * (t + 0.5)) * 0.2 + 0.2
		var col2 = cos(2 * PI * (t + 0.5)) * 0.5 + 0.5
		modulate = Color(1.0, 1.0 - col1, 1.0 - col2, 1.0)


func _on_mouse_entered():
	highlight = true
	t = 0.0


func _on_mouse_exited():
	highlight = false
	modulate = Color(1.0, 1.0, 1.0, 1.0)


func _input(event):
	if InputMap.has_action(action) and !event is InputEventJoypadMotion:
		if event.is_action(action):
			if event.pressed:
				controller_button.value = 1
			else:
				controller_button.value = 0
	elif event is InputEventJoypadMotion:
		if event.device == device and event.axis == axis:
			axis_range.axis_monitor.value = event.axis_value
			axis_value = event.axis_value
			check_action_state()


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				pressed = true
			elif pressed and !event.pressed:
				pressed = false
				var pos = event.position
				var rmax = rect_size
				if pos.x >= 0 and pos.x <= rmax.x and pos.y >= 0 and pos.y <= rmax.y:
					emit_signal("clicked")
				else:
					emit_signal("mouse_exited")


func update_binding(event: InputEvent):
	if event:
		var dict = Controls.action_dict[dict_idx]
		dict["bound"] = true
		if event is InputEventJoypadButton:
			if dict.has("axis"):
				remove_axis_range()
			InputMap.action_add_event(action, event)
			device = event.device
			button = event.button_index
			dict["type"] = "button"
			dict["button"] = event.button_index
		elif event is InputEventJoypadMotion:
			if dict.has("button"):
				dict.erase("button")
			if axis_range:
				remove_axis_range()
			add_axis_range(event)
			dict["type"] = "axis"
			dict["axis"] = axis
			if dict.has("min") and dict.has("max"):
				axis_range.call_deferred("set_bounds", dict["min"], dict["max"])
			else:
				dict["min"] = axis_range.bound_low
				dict["max"] = axis_range.bound_high
	else:
		remove_binding()
	emit_signal("binding_updated")
	check_action_state()


func remove_binding():
	remove_axis_range()
	button = -1
	device = -1
	Input.parse_input_event(simulate_action_event(action, false))
	var dict = Controls.action_dict[dict_idx]
	dict["bound"] = false
	for key in ["type", "button", "axis", "min", "max"]:
		dict.erase(key)


func add_axis_range(event: InputEventJoypadMotion):
	axis_range = GUIControllerAxisRange.new()
	add_child(axis_range)
	axis_range.connect("range_updated", self, "_on_axis_range_updated")
	axis_range.connect("range_released", self, "_on_axis_range_released")
	device = event.device
	axis = event.axis
	axis_value = Input.get_joy_axis(device, axis)


func remove_axis_range():
	if axis_range:
		remove_child(axis_range)
		axis_range.queue_free()
		axis_range = null
		axis = -1
		axis_value = 0.0


func _on_axis_range_updated():
	check_action_state()


func _on_axis_range_released():
	var dict = Controls.action_dict[dict_idx]
	if dict["bound"] and dict["type"] == "axis":
		dict["min"] = axis_range.bound_low
		dict["max"] = axis_range.bound_high
		emit_signal("binding_updated")


func check_action_state():
	var dict = Controls.action_dict[dict_idx]
	if dict.get("bound", false) == false:
		Input.parse_input_event(simulate_action_event(action, false))
	else:
		if dict["type"] == "button":
			Input.parse_input_event(simulate_action_event(action, Input.is_joy_button_pressed(device, button)))
		else:
			axis_range.axis_monitor.value = axis_value
			var bound_low = axis_range.bound_low
			var bound_high = axis_range.bound_high
			if !Input.is_action_pressed(action) and axis_value >= bound_low and axis_value <= bound_high:
				Input.parse_input_event(simulate_action_event(action, true))
			elif Input.is_action_pressed(action) and (axis_value < bound_low or axis_value > bound_high):
				Input.parse_input_event(simulate_action_event(action, false))


func simulate_action_event(action_name: String, action_pressed: bool) -> InputEventAction:
	var event = InputEventAction.new()
	event.action = action_name
	event.pressed = action_pressed
	return event
