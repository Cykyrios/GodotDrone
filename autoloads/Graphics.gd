extends Node


signal shadows_updated
signal fisheye_mode_changed
signal fisheye_resolution_changed
signal fisheye_msaa_changed


enum WindowMode {FULLSCREEN, FULLSCREEN_WINDOW, WINDOW, BORDERLESS_WINDOW}
enum GameMSAA {OFF, X2, X4, X8, X16}
enum GameAF {OFF = 0, X2 = 2, X4 = 4, X8 = 8, X16 = 16}
enum Shadows {OFF, LOW, MEDIUM, HIGH, ULTRA}
enum FisheyeMode {OFF, FULL, FAST}
enum FisheyeResolution {FISHEYE_2160P, FISHEYE_1080P,
		FISHEYE_720P, FISHEYE_480P, FISHEYE_240P}
enum FisheyeMSAA {OFF, SAME_AS_GAME, X2, X4, X8, X16}


var graphics_settings_path = "user://Graphics.cfg"

var graphics_settings = {"window_mode": WindowMode.FULLSCREEN,
		"resolution": "1920x1080",
		"msaa": GameMSAA.X4,
		"af": GameAF.X4,
		"shadows": Shadows.MEDIUM,
		"fisheye_mode": FisheyeMode.FULL,
		"fisheye_resolution": FisheyeResolution.FISHEYE_720P,
		"fisheye_msaa": FisheyeMSAA.SAME_AS_GAME}


func load_graphics_settings():
	var config = ConfigFile.new()
	var err = config.load(graphics_settings_path)
	if err == OK:
		for key in graphics_settings.keys:
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
	else:
		if err != ERR_FILE_NOT_FOUND:
			return "Could not open graphics config file: Error %s" % err


func save_graphics_settings():
	var config = ConfigFile.new()
	var err = config.load(graphics_settings_path)
	if err == OK or err == ERR_FILE_NOT_FOUND:
		for key in graphics_settings.keys():
			config.set_value("graphics", key, graphics_settings[key])
		config.save(graphics_settings_path)
	else:
		push_error("Error while saving graphics settings: %s" % err)


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
	ProjectSettings.set_setting("rendering/quality/filter/anisotropic_filter_level", graphics_settings["af"])


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
	emit_signal("fisheye_resolution_changed")


func update_fisheye_msaa():
	emit_signal("fisheye_msaa_changed")
