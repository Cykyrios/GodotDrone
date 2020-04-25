extends Control


var packed_options_menu = preload("res://GUI/OptionsMenu.tscn")
var packed_popup = preload("res://GUI/ConfirmationPopup.tscn")

var level = preload("res://Level1.tscn")


func _ready():
	$VBoxContainer/ButtonFly.connect("pressed", self, "_on_fly_pressed")
	$VBoxContainer/ButtonOptions.connect("pressed", self, "_on_options_pressed")
	$VBoxContainer/ButtonQuit.connect("pressed", self, "_on_quit_pressed")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	var error = load_input_map()
	if error:
		var controller_dialog = packed_popup.instance()
		add_child(controller_dialog)
		controller_dialog.set_text(error)
		controller_dialog.set_buttons("OK")
		controller_dialog.show_modal(true)
		var dialog = yield(controller_dialog, "validated")


func _on_fly_pressed():
	get_tree().change_scene_to(level)


func _on_options_pressed():
	if packed_options_menu.can_instance():
		var options_menu = packed_options_menu.instance()
		add_child(options_menu)
		$VBoxContainer.visible = false
		yield(options_menu, "back")
		options_menu.queue_free()
		$VBoxContainer.visible = true


func _on_quit_pressed():
	var confirm_dialog = packed_popup.instance()
	add_child(confirm_dialog)
	confirm_dialog.set_text("Do you really want to quit?")
	confirm_dialog.set_buttons("Quit", "Cancel")
	confirm_dialog.show_modal(true)
	var dialog = yield(confirm_dialog, "validated")
	if dialog == 0:
		get_tree().quit()


func load_input_map():
	var path = "user://InputMap.cfg"
	var config = ConfigFile.new()
	var err = config.load(path)
	if err == OK:
		var sections = config.get_sections() as Array
		var controller_list = Input.get_connected_joypads()
		for i in range(controller_list.size()):
			controller_list[i] = Input.get_joy_guid(controller_list[i])
		var active_guid = config.get_value("controls", "active_controller_guid")
		var active_device = controller_list.find(active_guid)
		if active_device >= 0:
			var section = "controls_%s" % [active_guid]
			var actions = config.get_section_keys(section)
			var event : InputEvent
			var current_axis = ""
			for action in actions:
				if ["throttle_up", "yaw_left", "pitch_up", "roll_left"].has(action):
					event = InputEventJoypadMotion.new()
					event.axis = Input.get_joy_axis_index_from_string(config.get_value(section, action))
					event.axis_value = -1.0
					current_axis = action
					continue
				elif ["throttle_inverted", "yaw_inverted", "pitch_inverted", "roll_inverted"].has(action):
					if config.get_value(section, action) == true:
						event.axis_value = 1.0
				event.device = active_device
				InputMap.action_erase_events(current_axis)
				InputMap.action_add_event(current_axis, event)
				if current_axis.ends_with("_up"):
					current_axis = current_axis.replace("up", "down")
					event = event.duplicate()
				elif current_axis.ends_with("_left"):
					current_axis = current_axis.replace("left", "right")
					event = event.duplicate()
				event.axis_value = -event.axis_value
				InputMap.action_erase_events(current_axis)
				InputMap.action_add_event(current_axis, event)
		else:
			var active_name = config.get_value("controls", "active_controller_name")
			var error = """%s not found!
					Please check it is properly plugged in,
					or head to the Controls settings to update your controller.""" % [active_name]
			return error
	else:
		if err != ERR_FILE_NOT_FOUND:
			return "Could not open config file.\nPlease check Control settings."
