extends Node


var input_map_path = "user://InputMap.cfg"
var active_controller_guid = ""
var default_controller_guid = ""

var startup = true


func update_active_device(device: int):
	var config = ConfigFile.new()
	var err = config.load(input_map_path)
	if err == OK:
		config.set_value("controls", "active_controller_guid", Input.get_joy_guid(device))
		config.set_value("controls", "active_controller_name", Input.get_joy_name(device))
		err = config.save(input_map_path)
	else:
		print_debug("Error while updating active device in config file")
	return err


func update_default_device(device: int):
	var config = ConfigFile.new()
	var err = config.load(input_map_path)
	if err == OK:
		default_controller_guid = Input.get_joy_guid(device)
		config.set_value("controls", "default_controller", default_controller_guid)
		err = config.save(input_map_path)
	else:
		print_debug("Error while updating default device in config file")
	return err


func load_input_map():
	var config = ConfigFile.new()
	var err = config.load(input_map_path)
	if err == OK:
		var sections = config.get_sections() as Array
		var controller_list = get_joypad_guid_list()
		var default_device = -1
		if config.has_section_key("controls", "default_controller"):
			default_controller_guid = config.get_value("controls", "default_controller")
			default_device = controller_list.find(default_controller_guid)
		active_controller_guid = config.get_value("controls", "active_controller_guid")
		var active_device = controller_list.find(active_controller_guid)
		if default_device >= 0:
			active_device = default_device
			active_controller_guid = default_controller_guid
			update_active_device(active_device)
		if active_device >= 0:
			var section = "controls_%s" % [active_controller_guid]
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
			return "Could not open config file.\nPlease check Controls settings."


func get_joypad_guid_list():
	var controller_list = Input.get_connected_joypads()
	for i in range(controller_list.size()):
		controller_list[i] = Input.get_joy_guid(controller_list[i])
	
	return controller_list
