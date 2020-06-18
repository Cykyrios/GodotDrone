extends Node


var game_settings_path := "user://GameSettings.cfg"

var hud_config := {"fps": 10, "crosshair": true, "horizon": true, "ladder": false,
		"speed": false, "altitude": false, "heading": false, "sticks": false, "rpm": false}


func load_hud_config():
	var config = ConfigFile.new()
	var err = config.load(game_settings_path)
	if err == OK:
		var hud_section := "hud_config"
		if config.has_section(hud_section):
			for key in config.get_section_keys(hud_section):
				var value = config.get_value(hud_section, key)
				if hud_config.has(key):
					if key == "fps" and (value is int or value is float):
						hud_config[key] = clamp(int(value), 5, 60)
					elif value is bool:
						hud_config[key] = value
	elif err != ERR_FILE_NOT_FOUND:
		push_error("Error while loading HUD config: %s" % err)


func save_hud_config():
	var config = ConfigFile.new()
	var err = config.load(game_settings_path)
	if err == OK or err == ERR_FILE_NOT_FOUND:
		for key in hud_config.keys():
			config.set_value("hud_config", key, hud_config[key])
		config.save(game_settings_path)
	else:
		push_error("Error while saving HUD config: %s" % err)
