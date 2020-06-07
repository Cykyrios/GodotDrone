extends Node


var quad_settings_path = "user://Quad.cfg"

var dry_weight: float = 0.55
var battery_weight: float = 0.18


func load_quad_settings():
	var config = ConfigFile.new()
	var err = config.load(quad_settings_path)
	if err == OK or err == ERR_FILE_NOT_FOUND:
		if config.has_section_key("quad", "dry_weight"):
			dry_weight = clamp(config.get_value("quad", "dry_weight"), 0.1, 1.0)
		if config.has_section_key("quad", "battery_weight"):
			battery_weight = clamp(config.get_value("quad", "battery_weight"), 0.1, 0.5)
	return err


func save_quad_settings():
	var config = ConfigFile.new()
	var err = config.load(quad_settings_path)
	if err == OK or err == ERR_FILE_NOT_FOUND:
		config.set_value("quad", "dry_weight", dry_weight)
		config.set_value("quad", "battery_weight", battery_weight)
		config.save(quad_settings_path)


func reset():
	dry_weight = 0.55
	battery_weight = 0.18
