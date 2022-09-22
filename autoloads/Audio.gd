extends Node


var audio_settings_path := "%s/Audio.cfg" % [Global.config_dir]

var audio_settings := {"master_volume": 1.0}


func load_audio_settings() -> String:
	var config := ConfigFile.new()
	var text := ""
	var err := config.load(audio_settings_path)
	if err == OK:
		for key in audio_settings.keys():
			if config.has_section_key("audio", key):
				audio_settings[key] = config.get_value("audio", key)
		update_master_volume()
	elif err == ERR_PARSE_ERROR:
		Global.log_error(err, "Parse error while loading audio configuration file.")
		text = "Failed to read audio configuration file."
		text = "%s\nThe default settings will be loaded." % text
	elif err != ERR_FILE_NOT_FOUND:
		Global.log_error(err, "Could not open audio config file.")
		text = "Could not open audio configuration file."
		text = "%s\nThe default settings will be loaded." % err
	return text


func save_audio_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(audio_settings_path)
	if err == OK or err == ERR_FILE_NOT_FOUND or err == ERR_PARSE_ERROR:
		for key in audio_settings.keys():
			config.set_value("audio", key, audio_settings[key])
		err = config.save(audio_settings_path)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		Global.log_error(err, "Error while saving audio settings.")


func update_master_volume() -> void:
	var volume: float = audio_settings["master_volume"]
	AudioServer.set_bus_volume_db(0, linear_to_db(volume))
