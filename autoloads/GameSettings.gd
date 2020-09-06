extends Node


signal hud_config_updated


var game_settings_path := "user://GameSettings.cfg"

var hud_config := {"fps": 10, "crosshair": true, "horizon": true, "ladder": false,
		"speed": false, "altitude": false, "heading": false, "sticks": false, "rpm": false}


func load_hud_config() -> void:
	var config := ConfigFile.new()
	var text := ""
	var err := config.load(game_settings_path)
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
		return
	elif err == ERR_PARSE_ERROR:
		Global.log_error(err, "Parse error while loading HUD config.")
		text = "Error parsing settings file, default settings will be loaded."
	elif err != ERR_FILE_NOT_FOUND:
		Global.log_error(err, "Error while loading HUD config.")
		text = "Error loading settings file, default settings will be loaded."
	Global.show_error_popup(get_tree().root.get_children()[-1], text)


func save_hud_config() -> void:
	var config := ConfigFile.new()
	var err := config.load(game_settings_path)
	if err == OK or err == ERR_FILE_NOT_FOUND or err == ERR_PARSE_ERROR:
		for key in hud_config.keys():
			config.set_value("hud_config", key, hud_config[key])
		var _discard = config.save(game_settings_path)
		emit_signal("hud_config_updated")
	else:
		Global.log_error(err, "Error while saving HUD config.")
