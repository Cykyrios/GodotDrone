extends Control


var packed_calibration_menu = preload("res://GUI/CalibrationMenu.tscn")
var packed_binding_popup = preload("res://GUI/ConfirmationPopup.tscn")
var binding_popup = null

onready var controller_list = $ControllerVBox/ControllerVBox/OptionButton
onready var controller_checkbutton = $ControllerVBox/ControllerVBox/ControllerCheckButton
onready var axes_list = $ControllerVBox/AxesVBox/AxesList
onready var button_grid = $ControllerVBox/ButtonsVBox/ButtonGrid

onready var actions_list = $BindingsVBox/ActionsVBox
var show_binding_popup = false
var binding_popup_text = ""
var binding_popup_clear = false
var binding_event = null

var connected_joypads = []
var auto_detect_controller = false
var active_controller = -1
var default_controller = -1

signal controller_detected
signal back


func _ready():
	connect("controller_detected", self, "_on_controller_autodetected")
	Input.connect("joy_connection_changed", self, "_on_joypad_connection_changed")
	
	$MenuVBox/ButtonCalibrate.connect("pressed", self, "_on_calibrate_pressed")
	$MenuVBox/ButtonBack.connect("pressed", self, "_on_back_pressed")
	
	controller_list.connect("pressed", self, "_on_controller_list_pressed")
	controller_list.get_popup().connect("id_pressed", self, "_on_controller_selected")
	controller_list.get_popup().connect("modal_closed", self, "_on_controller_select_aborted")
	controller_list.get_popup().add_font_override("font", load("res://GUI/MenuFont.tres"))
	controller_list.clip_text = true
	
	controller_checkbutton.connect("toggled", self, "_on_checkbutton_toggled")
	
	# TODO: only allow calibration for active controller OR update controller list
	
	# Controller selector, axes and buttons
	var axis = GUIControllerAxis.new()
	axis.size_flags_horizontal = 0
	for i in range(8):
		axes_list.add_child(axis.duplicate())
	axis.queue_free()
	
	var button = GUIControllerButton.new()
	button.size_flags_horizontal = SIZE_SHRINK_CENTER
	for i in range(16):
		button_grid.add_child(button.duplicate())
		button_grid.get_children()[-1].rect_min_size = Vector2(20, 20)
	button.queue_free()
	
	var active_controller_found = false
	var active_device = -1
	connected_joypads = Input.get_connected_joypads()
	for joypad in connected_joypads:
		if Input.get_joy_guid(joypad) == Global.active_controller_guid:
			active_controller_found = true
			active_device = joypad
			break
	if !active_controller_found:
		var default_controller_found = false
		if default_controller >= 0:
			for joypad in connected_joypads:
				if Input.get_joy_guid(joypad) == Global.default_controller_guid:
					default_controller_found = true
					default_controller = joypad
					active_device = joypad
		if !default_controller_found:
			if connected_joypads.empty():
				active_device = -1
			else:
				active_device = connected_joypads[0]
	controller_list.get_popup().emit_signal("id_pressed", connected_joypads.find(active_device))
	
	$ControllerVBox.rect_position.y = (rect_size - $ControllerVBox.rect_size).y / 2
	
	# Actions bindings
	for action in Global.action_dict:
		var binding = GUIControllerBinding.new()
		actions_list.add_child(binding)
		binding.action = action["action"]
		binding.label.text = action["label"]
		binding.connect("clicked", self, "_on_binding_clicked", [binding])
		binding.connect("binding_updated", self, "_on_binding_updated")
	
	# TODO: add animated radio sticks display with customizable mode1, mode2, etc.
	# TODO: add drone model that reacts to user input


func _input(event):
	if event is InputEventJoypadMotion or event is InputEventJoypadButton:
		if auto_detect_controller:
			if event is InputEventJoypadMotion and abs(event.axis_value) > 0.8 or event is InputEventJoypadButton:
				emit_signal("controller_detected", event.device)
		elif Input.get_joy_name(event.device) == controller_list.text:
			if event is InputEventJoypadMotion and event.axis < 8:
				update_axis_value(event.axis, event.axis_value)
			elif event is InputEventJoypadButton and event.button_index < 16:
				update_button_value(event.button_index, event.is_pressed())
			if show_binding_popup:
				var binding_text = ""
				var binding_valid = false
				if event is InputEventJoypadMotion and abs(event.axis_value) > 0.8:
					var axis = event.axis
					binding_text = "Axis %d (%s)" % [axis, Input.get_joy_axis_string(axis)]
					binding_valid = true
				elif event is InputEventJoypadButton and event.button_index < JOY_BUTTON_MAX:
					var button = event.button_index
					binding_text = "Button %d (%s)" % [button, Input.get_joy_button_string(button)]
					binding_valid = true
				if binding_valid:
					binding_event = event
					binding_popup.set_text(binding_popup_text + "\n%s" % [binding_text])


func _on_calibrate_pressed():
	if packed_calibration_menu.can_instance():
		var calibration_menu = packed_calibration_menu.instance()
		add_child(calibration_menu)
		$MenuVBox.visible = false
		yield(calibration_menu, "back")
		calibration_menu.queue_free()
		$MenuVBox.visible = true


func _on_back_pressed():
	emit_signal("back")


func update_controller_list():
	connected_joypads = Input.get_connected_joypads()
	controller_list.get_popup().clear()
	if connected_joypads.empty():
		controller_list.get_popup().add_item("No controller found")
		controller_list.text = "No controller found"
		active_controller = -1
		controller_checkbutton.disabled = true
		controller_checkbutton.pressed = false
	else:
		for joypad in connected_joypads:
			controller_list.get_popup().add_item(Input.get_joy_name(joypad))
		controller_checkbutton.disabled = false


func _on_joypad_connection_changed(device: int, connected: bool):
	update_controller_list()
	var active_controller_found = false
	for joypad in connected_joypads:
		if Input.get_joy_name(joypad) == controller_list.text:
			active_controller_found = true
			break
	if !active_controller_found:
		active_controller = -1
		controller_list.get_popup().emit_signal("id_pressed", active_controller)


func _on_controller_list_pressed():
	update_controller_list()
	auto_detect_controller = true


func _on_controller_select_aborted():
	auto_detect_controller = false


func _on_controller_autodetected(device: int):
	active_controller = device
	controller_list.get_popup().emit_signal("id_pressed", connected_joypads.find(device))


func _on_controller_selected(id: int):
	if controller_list.get_popup().visible:
		controller_list.get_popup().hide()
	auto_detect_controller = false
	if connected_joypads.empty():
		return
	if connected_joypads[id] != active_controller:
		active_controller = connected_joypads[id]
		var checkbutton_pressed = (Input.get_joy_guid(active_controller) == Global.default_controller_guid)
		controller_checkbutton.pressed = checkbutton_pressed
		Global.update_active_device(active_controller)
		call_deferred("update_input_map")
		call_deferred("update_axes_and_buttons", active_controller)


func _on_checkbutton_toggled(pressed: bool):
	if (!pressed and active_controller != default_controller) or (pressed and active_controller == default_controller):
		return
	if pressed:
		default_controller = active_controller
	else:
		default_controller = -1
	var err = Global.update_default_device(default_controller)
	if err != OK:
		print_debug("Controller checkbox input map save error")


func update_axes_and_buttons(device: int):
	controller_list.text = Input.get_joy_name(device)
	for i in range(8):
		update_axis_value(i, Input.get_joy_axis(device, i))
	for i in range(16):
		update_button_value(i, Input.is_joy_button_pressed(device, i))


func update_axis_value(id: int, value: float):
	axes_list.get_children()[id].value = value


func update_button_value(id: int, pressed: bool):
	var button = button_grid.get_children()[id]
	button.value = pressed as int


func update_input_map():
	for binding in actions_list.get_children():
		binding.remove_binding()
	Global.load_input_map()
	var dict_list = Global.action_dict
	for i in range(dict_list.size()):
		var dict = dict_list[i]
		var binding = actions_list.get_child(i)
		if dict["bound"]:
			if dict["type"] == "button":
				var event = InputEventJoypadButton.new()
				event.button_index = dict["button"]
				event.device = active_controller
				call_deferred("update_binding", binding, event)
			elif dict["type"] == "axis":
				var event = InputEventJoypadMotion.new()
				event.axis = dict["axis"]
				event.device = active_controller
				call_deferred("update_binding", binding, event)


func save_input_map():
	var section = "controls_" + Global.active_controller_guid
	var config = ConfigFile.new()
	var err = config.load(Global.input_map_path)
	if err == OK:
		for action in Global.action_dict:
			var action_name = action["action"]
			if config.has_section_key(section, action_name):
				config.erase_section_key(section, action_name)
				for key in ["_button", "_axis", "_min", "_max"]:
					if config.has_section_key(section, action_name + key):
						config.erase_section_key(section, action_name + key)
			if action.has("bound") and action["bound"]:
				config.set_value(section, action_name, action["type"])
				if action["type"] == "button":
					config.set_value(section, action_name + "_button", Input.get_joy_button_string(action["button"]))
				else:
					config.set_value(section, action_name + "_axis", Input.get_joy_axis_string(action["axis"]))
					config.set_value(section, action_name + "_min", action["min"])
					config.set_value(section, action_name + "_max", action["max"])
		err = config.save(Global.input_map_path)


func update_binding(binding: GUIControllerBinding, event: InputEvent):
	var action = binding.action
	binding.dict_idx = actions_list.get_children().find(binding)
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
		binding.update_binding(event)


func _on_binding_clicked(binding: GUIControllerBinding):
	binding_popup = packed_binding_popup.instance()
	add_child(binding_popup)
	binding_popup_text = "Press a button or flip a switch\nfor action: %s" % [binding.label.text]
	var current_binding_text = "..."
	if !binding_popup_clear:
		if binding.device >= 0 and binding.axis >= 0:
			current_binding_text = Input.get_joy_axis_string(binding.axis)
		var action_events = InputMap.get_action_list(binding.action)
		if !action_events.empty():
			if action_events[0] is InputEventJoypadMotion:
				var axis = action_events[0].axis
				current_binding_text = "Axis %d (%s)" % [axis, Input.get_joy_axis_string(axis)]
			elif action_events[0] is InputEventJoypadButton:
				var button = action_events[0].button_index
				current_binding_text = "Button %d (%s)"  % [button, Input.get_joy_button_string(button)]
	binding_popup.set_text(binding_popup_text + "\n" + current_binding_text)
	binding_popup.set_buttons("Confirm", "Cancel", "Clear")
	show_binding_popup = true
	binding_popup.show_modal(true)
	var popup = yield(binding_popup, "validated")
	binding_popup.queue_free()
	binding_popup = null
	show_binding_popup = false
	match popup:
		0:
			if binding_event or binding_popup_clear and !binding_event:
				update_binding(binding, binding_event)
				binding_event = null
				binding_popup_clear = false
		1:
			binding_popup_clear = false
		2:
			binding_event = null
			binding_popup_clear = true
			binding.emit_signal("clicked")


func _on_binding_updated():
	save_input_map()
