extends Node


signal settings_updated


var quad_settings_path := "%s/Quad.cfg" % [Global.config_dir]

var angle := 30
var dry_weight := 0.55
var battery_weight := 0.18

var control_profile := ControlProfile.new()


func load_quad_settings() -> void:
	var config := ConfigFile.new()
	var text := ""
	var err := config.load(quad_settings_path)
	if err == OK:
		if config.has_section_key("quad", "angle"):
			angle = clampf(config.get_value("quad", "angle"), -20, 80) as int
		if config.has_section_key("quad", "dry_weight"):
			dry_weight = clampf(config.get_value("quad", "dry_weight"), 0.1, 1.0)
		if config.has_section_key("quad", "battery_weight"):
			battery_weight = clampf(config.get_value("quad", "battery_weight"), 0.1, 0.5)
		if config.has_section_key("rates", "rate_curve"):
			control_profile.rate_curve = config.get_value("rates", "rate_curve") as ControlProfile.RateCurve
		if config.has_section_key("rates", "pitch_rate"):
			control_profile.pitch_rate = clampf(config.get_value("rates", "pitch_rate"), 90, 1800) as int
		if config.has_section_key("rates", "roll_rate"):
			control_profile.roll_rate = clampf(config.get_value("rates", "roll_rate"), 90, 1800) as int
		if config.has_section_key("rates", "yaw_rate"):
			control_profile.yaw_rate = clampf(config.get_value("rates", "yaw_rate"), 90, 1800) as int
		if config.has_section_key("rates", "pitch_rc"):
			control_profile.pitch_rc = clampf(config.get_value("rates", "pitch_rc"), 10, 1800) as int
		if config.has_section_key("rates", "roll_rc"):
			control_profile.roll_rc = clampf(config.get_value("rates", "roll_rc"), 10, 1800) as int
		if config.has_section_key("rates", "yaw_rc"):
			control_profile.yaw_rc = clampf(config.get_value("rates", "yaw_rc"), 10, 1800) as int
		if config.has_section_key("rates", "pitch_expo"):
			control_profile.pitch_expo = clampf(config.get_value("rates", "pitch_expo"), 0.0, 1.0)
		if config.has_section_key("rates", "roll_expo"):
			control_profile.roll_expo = clampf(config.get_value("rates", "roll_expo"), 0.0, 1.0)
		if config.has_section_key("rates", "yaw_expo"):
			control_profile.yaw_expo = clampf(config.get_value("rates", "yaw_expo"), 0.0, 1.0)
		return
	elif err == ERR_PARSE_ERROR:
		Global.log_error(err, "Parse error while loading quad settings.")
		text = "Parse error while loading settings. Default settings will be loaded."
	elif err == ERR_FILE_NOT_FOUND:
		save_quad_settings()
		return
	else:
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
		config.set_value("rates", "rate_curve", control_profile.rate_curve)
		config.set_value("rates", "pitch_rate", control_profile.pitch_rate)
		config.set_value("rates", "roll_rate", control_profile.roll_rate)
		config.set_value("rates", "yaw_rate", control_profile.yaw_rate)
		config.set_value("rates", "pitch_rc", control_profile.pitch_rc)
		config.set_value("rates", "roll_rc", control_profile.roll_rc)
		config.set_value("rates", "yaw_rc", control_profile.yaw_rc)
		config.set_value("rates", "pitch_expo", control_profile.pitch_expo)
		config.set_value("rates", "roll_expo", control_profile.roll_expo)
		config.set_value("rates", "yaw_expo", control_profile.yaw_expo)
		var _discard = config.save(quad_settings_path)
	else:
		Global.log_error(err, "Error while saving quad settings.")
	settings_updated.emit()


func reset_quad() -> void:
	angle = 30
	dry_weight = 0.55
	battery_weight = 0.18


func reset_rates() -> void:
	match control_profile.rate_curve:
		ControlProfile.RateCurve.ACTUAL:
			control_profile.pitch_rate = 720
			control_profile.roll_rate = 720
			control_profile.yaw_rate = 720
			control_profile.pitch_rc = 180
			control_profile.roll_rc = 180
			control_profile.yaw_rc = 180
			control_profile.pitch_expo = 0.2
			control_profile.roll_expo = 0.2
			control_profile.yaw_expo = 0.2
		ControlProfile.RateCurve.RACEFLIGHT:
			control_profile.pitch_rate = 400
			control_profile.roll_rate = 400
			control_profile.yaw_rate = 400
			control_profile.pitch_rc = 80
			control_profile.roll_rc = 80
			control_profile.yaw_rc = 80
			control_profile.pitch_expo = 0.5
			control_profile.roll_expo = 0.5
			control_profile.yaw_expo = 0.5
		ControlProfile.RateCurve.KISS:
			control_profile.pitch_rate = 70
			control_profile.roll_rate = 70
			control_profile.yaw_rate = 70
			control_profile.pitch_rc = 100
			control_profile.roll_rc = 100
			control_profile.yaw_rc = 100
			control_profile.pitch_expo = 0.0
			control_profile.roll_expo = 0.0
			control_profile.yaw_expo = 0.0
		ControlProfile.RateCurve.QUICKRATES:
			control_profile.pitch_rate = 720
			control_profile.roll_rate = 720
			control_profile.yaw_rate = 720
			control_profile.pitch_rc = 100
			control_profile.roll_rc = 100
			control_profile.yaw_rc = 100
			control_profile.pitch_expo = 0.0
			control_profile.roll_expo = 0.0
			control_profile.yaw_expo = 0.0
