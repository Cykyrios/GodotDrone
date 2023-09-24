extends Node


signal shadows_updated
signal fisheye_mode_changed
signal fisheye_resolution_changed
signal fisheye_msaa_changed


enum WindowMode {FULLSCREEN, WINDOW, BORDERLESS_WINDOW}
enum GameMSAA {OFF, X2, X4, X8, X16}
enum GameAF {OFF, X2, X4, X8, X16}
enum Shadows {VERY_LOW, LOW, MEDIUM, HIGH, ULTRA}
enum FisheyeMode {OFF, FULL, FAST}
enum FisheyeResolution {FISHEYE_2160P, FISHEYE_1440P, FISHEYE_1080P,
		FISHEYE_720P, FISHEYE_480P, FISHEYE_240P}
enum FisheyeMSAA {OFF, X2, X4, X8, X16, SAME_AS_GAME}


var graphics_settings_path := "%s/Graphics.cfg" % [Global.config_dir]

var graphics_settings := {
	"window_mode": WindowMode.FULLSCREEN,
	"resolution": "100",
	"msaa": GameMSAA.X4,
	"af": GameAF.X4,
	"shadows": Shadows.MEDIUM,
	"fisheye_mode": FisheyeMode.FULL,
	"fisheye_resolution": FisheyeResolution.FISHEYE_720P,
	"fisheye_msaa": FisheyeMSAA.SAME_AS_GAME,
}
var fisheye_resolution := 720


func load_graphics_settings() -> String:
	var config := ConfigFile.new()
	var text := ""
	var err := config.load(graphics_settings_path)
	if err == OK:
		for key: String in graphics_settings.keys():
			if config.has_section_key("graphics", key):
				graphics_settings[key] = config.get_value("graphics", key)
		update_window_mode()
		update_resolution()
		update_msaa()
		update_af()
		update_shadows()
		update_fisheye_mode()
		update_fisheye_resolution()
		update_fisheye_msaa()
	elif err == ERR_PARSE_ERROR:
		Global.log_error(err, "Parse error while loading graphics configuration file.")
		text = "Failed to read graphics configuration file."
		text = "%s\nThe default settings will be loaded." % [text]
	elif err != ERR_FILE_NOT_FOUND:
		Global.log_error(err, "Could not open graphics config file.")
		text = "Could not open graphics configuration file."
		text = "%s\nThe defaut settings will be loaded." % [err]
	return text


func save_graphics_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(graphics_settings_path)
	if err == OK or err == ERR_FILE_NOT_FOUND or err == ERR_PARSE_ERROR:
		for key: String in graphics_settings.keys():
			config.set_value("graphics", key, graphics_settings[key])
		err = config.save(graphics_settings_path)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		Global.log_error(err, "Error while saving graphics settings.")


func update_window_mode() -> void:
	var mode := graphics_settings["window_mode"] as WindowMode
	var window := get_tree().root as Window
	if mode == WindowMode.FULLSCREEN:
		window.mode = Window.MODE_FULLSCREEN
		window.size = DisplayServer.screen_get_size()
	else:
		window.mode = Window.MODE_WINDOWED
		window.unresizable = false
		if window.size > DisplayServer.screen_get_size():
			window.size = DisplayServer.screen_get_size()
		window.borderless = true if mode == WindowMode.BORDERLESS_WINDOW else false


func update_resolution() -> void:
	var resolution_multiplier := float(graphics_settings["resolution"]) / 100.0
	var screen_resolution := DisplayServer.screen_get_size()
	var mode: int = graphics_settings["window_mode"]
	if mode == WindowMode.FULLSCREEN:
		DisplayServer.window_set_size(DisplayServer.screen_get_size())
	else:
		DisplayServer.window_set_size(screen_resolution * resolution_multiplier)
		DisplayServer.window_set_position(
				(DisplayServer.screen_get_size() - DisplayServer.window_get_size()) / 2)
	get_viewport().size = screen_resolution * resolution_multiplier


func update_msaa() -> void:
	get_viewport().msaa_3d = graphics_settings["msaa"]
	if graphics_settings["fisheye_msaa"] == FisheyeMSAA.SAME_AS_GAME:
		update_fisheye_msaa()


func update_af() -> void:
	pass
	#TODO: implement the Godot 4 way of AF, by looping through all materials?


func update_shadows(viewport: Viewport = null) -> void:
	if not viewport:
		viewport = get_viewport() as Viewport
	match graphics_settings["shadows"]:
		Shadows.VERY_LOW:
			viewport.positional_shadow_atlas_size = 512
			RenderingServer.directional_shadow_atlas_set_size(512, true)
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
			RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
		Shadows.LOW:
			viewport.positional_shadow_atlas_size = 1024
			RenderingServer.directional_shadow_atlas_set_size(1024, true)
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
			RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
		Shadows.MEDIUM:
			viewport.positional_shadow_atlas_size = 4096
			RenderingServer.directional_shadow_atlas_set_size(4096, true)
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM)
			RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM)
		Shadows.HIGH:
			viewport.positional_shadow_atlas_size = 8192
			RenderingServer.directional_shadow_atlas_set_size(8192, true)
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
			RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
		Shadows.ULTRA:
			viewport.positional_shadow_atlas_size = 16384
			RenderingServer.directional_shadow_atlas_set_size(16384, true)
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_ULTRA)
			RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_ULTRA)
	shadows_updated.emit()


func update_fisheye_mode() -> void:
	fisheye_mode_changed.emit()


func update_fisheye_resolution(resolution_string: String = "") -> void:
	var new_resolution: int
	match resolution_string:
		"2160p":
			new_resolution = FisheyeResolution.FISHEYE_2160P
		"1440p":
			new_resolution = FisheyeResolution.FISHEYE_1440P
		"1080p":
			new_resolution = FisheyeResolution.FISHEYE_1080P
		"720p":
			new_resolution = FisheyeResolution.FISHEYE_720P
		"480p":
			new_resolution = FisheyeResolution.FISHEYE_480P
		"240p":
			new_resolution = FisheyeResolution.FISHEYE_240P
		"":
			new_resolution = graphics_settings["fisheye_resolution"]
	graphics_settings["fisheye_resolution"] = new_resolution
	match graphics_settings["fisheye_resolution"]:
		FisheyeResolution.FISHEYE_2160P:
			fisheye_resolution = 2160
		FisheyeResolution.FISHEYE_1440P:
			fisheye_resolution = 1440
		FisheyeResolution.FISHEYE_1080P:
			fisheye_resolution = 1080
		FisheyeResolution.FISHEYE_720P:
			fisheye_resolution = 720
		FisheyeResolution.FISHEYE_480P:
			fisheye_resolution = 480
		FisheyeResolution.FISHEYE_240P:
			fisheye_resolution = 240
	fisheye_resolution_changed.emit()


func update_fisheye_msaa() -> void:
	fisheye_msaa_changed.emit()


func get_fisheye_resolution(resolution_setting: int) -> int:
	var resolution: int
	match resolution_setting:
		FisheyeResolution.FISHEYE_2160P:
			resolution = 2160
		FisheyeResolution.FISHEYE_1440P:
			resolution = 1440
		FisheyeResolution.FISHEYE_1080P:
			resolution = 1080
		FisheyeResolution.FISHEYE_720P:
			resolution = 720
		FisheyeResolution.FISHEYE_480P:
			resolution = 480
		FisheyeResolution.FISHEYE_240P:
			resolution = 240
	return resolution