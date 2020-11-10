extends Node


signal settings_updated


var quad_settings_path := "%s/Quad.cfg" % Global.config_dir

var angle := 30
var dry_weight := 0.55
var battery_weight := 0.18

var rate_pitch := 667
var rate_roll := 667
var rate_yaw := 667
var expo_pitch := 0.2
var expo_roll := 0.2
var expo_yaw := 0.2


func load_quad_settings() -> void:
	var config := ConfigFile.new()
	var text := ""
	var err := config.load(quad_settings_path)
	if err == OK:
		if config.has_section_key("quad", "angle"):
			angle = int(clamp(config.get_value("quad", "angle"), -20, 80))
		if config.has_section_key("quad", "dry_weight"):
			dry_weight = clamp(config.get_value("quad", "dry_weight"), 0.1, 1.0)
		if config.has_section_key("quad", "battery_weight"):
			battery_weight = clamp(config.get_value("quad", "battery_weight"), 0.1, 0.5)
		if config.has_section_key("rates", "pitch"):
			rate_pitch = int(clamp(config.get_value("rates", "pitch"), 90, 1800))
		if config.has_section_key("rates", "roll"):
			rate_roll = int(clamp(config.get_value("rates", "roll"), 90, 1800))
		if config.has_section_key("rates", "yaw"):
			rate_yaw = int(clamp(config.get_value("rates", "yaw"), 90, 1800))
		if config.has_section_key("expos", "pitch"):
			expo_pitch = clamp(config.get_value("expos", "pitch"), 0.0, 1.0)
		if config.has_section_key("expos", "roll"):
			expo_roll = clamp(config.get_value("expos", "roll"), 0.0, 1.0)
		if config.has_section_key("expos", "yaw"):
			expo_yaw = clamp(config.get_value("expos", "yaw"), 0.0, 1.0)
		return
	elif err == ERR_PARSE_ERROR:
		Global.log_error(err, "Parse error while loading quad settings.")
		text = "Parse error while loading settings. Default settings will be loaded."
	elif err != ERR_FILE_NOT_FOUND:
		Global.log_error(err, "Error loading quad settings.")
		text = "Error loading settings. Default settings will be loaded."
	Global.show_error_popup(get_tree().root.get_children()[-1], text)


func save_quad_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(quad_settings_path)
	if err == OK or err == ERR_FILE_NOT_FOUND or err == ERR_PARSE_ERROR:
		config.set_value("quad", "angle", angle)
		config.set_value("quad", "dry_weight", dry_weight)
		config.set_value("quad", "battery_weight", battery_weight)
		config.set_value("rates", "pitch", rate_pitch)
		config.set_value("rates", "roll", rate_roll)
		config.set_value("rates", "yaw", rate_yaw)
		config.set_value("expos", "pitch", expo_pitch)
		config.set_value("expos", "roll", expo_roll)
		config.set_value("expos", "yaw", expo_yaw)
		var _discard = config.save(quad_settings_path)
	else:
		Global.log_error(err, "Error while saving quad settings.")
	emit_signal("settings_updated")


func reset_quad() -> void:
	angle = 30
	dry_weight = 0.55
	battery_weight = 0.18


func reset_rates() -> void:
	rate_pitch = 667
	rate_roll = 667
	rate_yaw = 667
	expo_pitch = 0.2
	expo_roll = 0.2
	expo_yaw = 0.2
