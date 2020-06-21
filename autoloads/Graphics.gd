extends Node


signal shadows_updated
signal fisheye_mode_changed
signal fisheye_resolution_changed
signal fisheye_msaa_changed


enum WindowMode {FULLSCREEN, FULLSCREEN_WINDOW, WINDOW, BORDERLESS_WINDOW}
enum GameMSAA {OFF, X2, X4, X8, X16}
enum GameAF {OFF, X2, X4, X8, X16}
enum Shadows {OFF, LOW, MEDIUM, HIGH, ULTRA}
enum FisheyeMode {OFF, FULL, FAST}
enum FisheyeResolution {FISHEYE_2160P, FISHEYE_1440P, FISHEYE_1080P,
		FISHEYE_720P, FISHEYE_480P, FISHEYE_240P}
enum FisheyeMSAA {OFF, X2, X4, X8, X16, SAME_AS_GAME}


var graphics_settings_path = "user://Graphics.cfg"

var graphics_settings = {"window_mode": WindowMode.FULLSCREEN,
		"resolution": "1920x1080",
		"msaa": GameMSAA.X4,
		"af": GameAF.X4,
		"shadows": Shadows.MEDIUM,
		"fisheye_mode": FisheyeMode.FULL,
		"fisheye_resolution": FisheyeResolution.FISHEYE_720P,
		"fisheye_msaa": FisheyeMSAA.SAME_AS_GAME}
var fisheye_resolution: int = 720

func _ready():
	load_graphics_settings()


func load_graphics_settings():
	var config = ConfigFile.new()
	var err = config.load(graphics_settings_path)
	if err == OK:
		for key in graphics_settings.keys():
			if config.has_section_key("graphics", key):
				graphics_settings[key] = config.get_value("graphics", key)
#			else:
#				# Load default value
#				var value
#				match key:
#					"window_mode":
#						value = WindowMode.FULLSCREEN
#					"resolution":
#						value = "Native"
#					"msaa":
#						value = GameMSAA.X4
#					"af":
#						value = GameAF.X8
#					"shadows":
#						value = Shadows.MEDIUM
#					"fisheye_mode":
#						value = FisheyeMode.FULL
#					"fisheye_resolution":
#						value = FisheyeResolution.FISHEYE_720P
#					"fisheye_msaa":
#						value = FisheyeMSAA.SAME_AS_GAME
#				graphics_settings[key] = value
		update_window_mode()
		update_msaa()
		update_af()
		update_shadows()
		update_fisheye_mode()
		update_fisheye_resolution()
		update_fisheye_msaa()
	elif err != ERR_FILE_NOT_FOUND:
		Global.log_error(err, "Could not open graphics config file.")
		return "Could not open graphics config file: Error %s" % err


func save_graphics_settings():
	var config = ConfigFile.new()
	var err = config.load(graphics_settings_path)
	if err == OK or err == ERR_FILE_NOT_FOUND:
		for key in graphics_settings.keys():
			config.set_value("graphics", key, graphics_settings[key])
		err = config.save(graphics_settings_path)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		Global.log_error(err, "Error while saving graphics settings.")


func update_window_mode():
	var mode = graphics_settings["window_mode"]
	if mode == WindowMode.FULLSCREEN:
		OS.window_fullscreen = true
		OS.window_size = OS.get_screen_size()
		OS.window_resizable = false
	else:
		OS.window_fullscreen = false
		if mode == WindowMode.FULLSCREEN_WINDOW:
			OS.window_borderless = true
			OS.window_size = OS.get_screen_size()
			OS.window_resizable = false
		else:
			OS.window_resizable = true
			if OS.window_size > OS.get_screen_size():
				OS.window_size = OS.get_screen_size()
			if mode == WindowMode.BORDERLESS_WINDOW:
				OS.window_borderless = true
			else:
				OS.window_borderless = false


func update_resolution():
	var resolution_string = graphics_settings["resolution"].split("x")
	var resolution = Vector2(int(resolution_string[0]), int(resolution_string[1]))
	var mode = graphics_settings["window_mode"]
	if mode == WindowMode.FULLSCREEN or mode == WindowMode.FULLSCREEN_WINDOW:
		OS.window_size = OS.get_screen_size()
		get_viewport().size = resolution
	else:
		OS.window_size = resolution
		get_viewport().size = OS.window_size


func update_msaa():
	get_viewport().msaa = graphics_settings["msaa"]
	if graphics_settings["fisheye_msaa"] == FisheyeMSAA.SAME_AS_GAME:
		update_fisheye_msaa()


func update_af():
	ProjectSettings.set_setting("rendering/quality/filters/anisotropic_filter_level", \
			int(pow(2, graphics_settings["af"])))
	var err = ProjectSettings.save()
	if err != OK:
		Global.log_error(err, "Failed to save AF settings.")


func update_shadows(viewport: Viewport = null):
	if not viewport:
		viewport = get_viewport()
	match graphics_settings["shadows"]:
		Shadows.OFF:
			viewport.shadow_atlas_size = 4096
			viewport.shadow_atlas_quad_0 = 0
			viewport.shadow_atlas_quad_1 = 0
			viewport.shadow_atlas_quad_2 = 0
			viewport.shadow_atlas_quad_3 = 0
		Shadows.LOW:
			viewport.shadow_atlas_size = 4096
			viewport.shadow_atlas_quad_0 = 1
			viewport.shadow_atlas_quad_1 = 2
			viewport.shadow_atlas_quad_2 = 3
			viewport.shadow_atlas_quad_3 = 4
		Shadows.MEDIUM:
			viewport.shadow_atlas_size = 4096
			viewport.shadow_atlas_quad_0 = 2
			viewport.shadow_atlas_quad_1 = 3
			viewport.shadow_atlas_quad_2 = 4
			viewport.shadow_atlas_quad_3 = 5
		Shadows.HIGH:
			viewport.shadow_atlas_size = 4096
			viewport.shadow_atlas_quad_0 = 3
			viewport.shadow_atlas_quad_1 = 4
			viewport.shadow_atlas_quad_2 = 5
			viewport.shadow_atlas_quad_3 = 6
		Shadows.ULTRA:
			viewport.shadow_atlas_size = 8192
			viewport.shadow_atlas_quad_0 = 3
			viewport.shadow_atlas_quad_1 = 4
			viewport.shadow_atlas_quad_2 = 5
			viewport.shadow_atlas_quad_3 = 6
	emit_signal("shadows_updated")


func update_fisheye_mode():
	emit_signal("fisheye_mode_changed")


func update_fisheye_resolution(resolution_string: String = ""):
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
	emit_signal("fisheye_resolution_changed")


func update_fisheye_msaa():
	emit_signal("fisheye_msaa_changed")


func get_fisheye_resolution(resolution_setting: int):
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
