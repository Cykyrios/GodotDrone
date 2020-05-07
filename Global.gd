extends Node


var input_map_path = "user://InputMap.cfg"
var active_controller_guid = ""
var default_controller_guid = ""

var startup = true

var action_dict = [{"action": "arm", "label": "Arm"},
		{"action": "toggle_arm", "label": "Arm (toggle)"},
		{"action": "respawn", "label": "Reset drone"},
		{"action": "cycle_flight_modes", "label": "Cycle modes"},
		{"action": "mode_horizon", "label": "Mode: Horizon"},
		{"action": "mode_angle", "label": "Mode: Angle"},
		{"action": "mode_speed", "label": "Mode: Speed"},
		{"action": "mode_position", "label": "Mode: Position"},
		{"action": "altitude_hold", "label": "Altitude hold"}]


func update_active_device(device: int):
	active_controller_guid = Input.get_joy_guid(device)
	var config = ConfigFile.new()
	var err = config.load(input_map_path)
	if err == OK:
		config.set_value("controls", "active_controller_guid", active_controller_guid)
		config.set_value("controls", "active_controller_name", Input.get_joy_name(device))
		err = config.save(input_map_path)
	else:
		print_debug("Error while updating active device in config file")
	return err


func update_default_device(device: int):
	var config = ConfigFile.new()
	var err = config.load(input_map_path)
	if err == OK:
		if device >= 0:
			default_controller_guid = Input.get_joy_guid(device)
		else:
			default_controller_guid = ""
		config.set_value("controls", "default_controller", default_controller_guid)
		err = config.save(input_map_path)
	else:
		print_debug("Error while updating default device in config file")
	return err


func load_input_map(update_controller: bool = false):
	var config = ConfigFile.new()
	var err = config.load(input_map_path)
	if err == OK:
		var sections = config.get_sections() as Array
		var controller_list = get_joypad_guid_list()
		active_controller_guid = config.get_value("controls", "active_controller_guid")
		var active_device = controller_list.find(active_controller_guid)
		if update_controller:
			var default_device = -1
			if config.has_section_key("controls", "default_controller"):
				default_controller_guid = config.get_value("controls", "default_controller")
				default_device = controller_list.find(default_controller_guid)
			if default_device >= 0:
				active_device = default_device
				active_controller_guid = default_controller_guid
				update_active_device(active_device)
			if default_device < 0 and !Input.get_connected_joypads().empty():
				active_device = Input.get_connected_joypads()[0]
				update_active_device(active_device)
		if active_device >= 0:
			var section = "controls_%s" % [active_controller_guid]
			var actions = config.get_section_keys(section)
			var event : InputEvent
			var current_action = ""
			var dict_idx = -1
			var binding_type = ""
			for action in actions:
				if action.begins_with("throttle") or action.begins_with("yaw") \
						or action.begins_with("pitch") or action.begins_with("roll"):
					if ["throttle_up", "yaw_left", "pitch_up", "roll_left"].has(action):
						event = InputEventJoypadMotion.new()
						event.axis = Input.get_joy_axis_index_from_string(config.get_value(section, action))
						event.axis_value = -1.0
						current_action = action
						continue
					elif ["throttle_inverted", "yaw_inverted", "pitch_inverted", "roll_inverted"].has(action):
						if config.get_value(section, action) == true:
							event.axis_value = 1.0
					event.device = active_device
					InputMap.action_erase_events(current_action)
					InputMap.action_add_event(current_action, event)
					if current_action.ends_with("_up"):
						current_action = current_action.replace("up", "down")
						event = event.duplicate()
					elif current_action.ends_with("_left"):
						current_action = current_action.replace("left", "right")
						event = event.duplicate()
					event.axis_value = -event.axis_value
					InputMap.action_erase_events(current_action)
					InputMap.action_add_event(current_action, event)
				else:
					if InputMap.has_action(action):
						current_action = action
						InputMap.action_erase_events(current_action)
						binding_type = config.get_value(section, action)
						for i in range(action_dict.size()):
							if action_dict[i]["action"] == action:
								dict_idx = i
								action_dict[dict_idx]["bound"] = true
								break
							dict_idx = -1
						continue
					if binding_type == "button":
						if action == current_action + "_button":
							action_dict[dict_idx]["button"] = Input.get_joy_button_index_from_string(config.get_value(section, action))
							event = InputEventJoypadButton.new()
							event.device = active_device
							event.button_index = action_dict[dict_idx]["button"]
							InputMap.action_add_event(current_action, event)
					elif binding_type == "axis":
						if action == current_action + "_axis":
							action_dict[dict_idx]["axis"] = Input.get_joy_axis_index_from_string(config.get_value(section, action))
						elif action == current_action + "_min":
							action_dict[dict_idx]["min"] = config.get_value(section, action)
						elif action == current_action + "_max":
							action_dict[dict_idx]["max"] = config.get_value(section, action)
			fill_dict_keys()
		else:
			var active_name = config.get_value("controls", "active_controller_name")
			var error = """%s not found!
					Please check it is properly plugged in,
					or head to the Controls settings to update your controller.""" % [active_name]
			return error
	else:
		if err != ERR_FILE_NOT_FOUND:
			return "Could not open config file.\nPlease check Controls settings."


func fill_dict_keys():
	for dict in action_dict:
		if !dict.has("bound"):
			dict["bound"] = false
		if !dict.has("type"):
			if dict["bound"]:
				if dict.has("button"):
					dict["type"] = "button"
				elif dict.has("axis"):
					dict["type"] = "axis"
			else:
				dict["type"] = ""
		if dict.has("axis"):
			if !dict.has("min"):
				dict["min"] = 0.0
			if !dict.has("max"):
				dict["max"] = 1.0


func get_joypad_guid_list():
	var controller_list = Input.get_connected_joypads()
	for i in range(controller_list.size()):
		controller_list[i] = Input.get_joy_guid(controller_list[i])
	
	return controller_list
