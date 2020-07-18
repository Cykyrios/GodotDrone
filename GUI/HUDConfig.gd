extends HBoxContainer


onready var fps := $ScrollContainer/VBoxContainer/HBoxContainer/SpinBoxRefreshRate
onready var check_crosshair := $ScrollContainer/VBoxContainer/CheckCrosshair
onready var check_horizon := $ScrollContainer/VBoxContainer/CheckHorizon
onready var check_ladder := $ScrollContainer/VBoxContainer/CheckLadder
onready var check_speed := $ScrollContainer/VBoxContainer/CheckSpeed
onready var check_altitude := $ScrollContainer/VBoxContainer/CheckAltitude
onready var check_heading := $ScrollContainer/VBoxContainer/CheckHeading
onready var check_sticks := $ScrollContainer/VBoxContainer/CheckSticks
onready var check_rpm := $ScrollContainer/VBoxContainer/CheckRPM

onready var hud := $HUD


func _ready() -> void:
	GameSettings.load_hud_config()
	var _discard = fps.connect("value_changed", self, "_on_hud_fps_changed")
	fps.value = GameSettings.hud_config["fps"]
	var buttons := [check_crosshair, check_horizon, check_ladder, check_speed,
			check_altitude, check_heading, check_sticks, check_rpm]
	for button in buttons:
		button.connect("toggled", self, "_on_button_toggled", [button])
		match button:
			check_crosshair:
				button.pressed = GameSettings.hud_config["crosshair"]
				hud.show_component(HUD.Component.CROSSHAIR, button.pressed)
			check_horizon:
				button.pressed = GameSettings.hud_config["horizon"]
				hud.show_component(HUD.Component.HORIZON, button.pressed)
			check_ladder:
				button.pressed = GameSettings.hud_config["ladder"]
				hud.show_component(HUD.Component.LADDER, button.pressed)
			check_speed:
				button.pressed = GameSettings.hud_config["speed"]
				hud.show_component(HUD.Component.SPEED, button.pressed)
			check_altitude:
				button.pressed = GameSettings.hud_config["altitude"]
				hud.show_component(HUD.Component.ALTITUDE, button.pressed)
			check_heading:
				button.pressed = GameSettings.hud_config["heading"]
				hud.show_component(HUD.Component.HEADING, button.pressed)
			check_sticks:
				button.pressed = GameSettings.hud_config["sticks"]
				hud.show_component(HUD.Component.STICKS, button.pressed)
			check_rpm:
				button.pressed = GameSettings.hud_config["rpm"]
				hud.show_component(HUD.Component.RPM, button.pressed)


func _on_hud_fps_changed(value: float) -> void:
	GameSettings.hud_config["fps"] = int(value)
	hud.hud_timer = 1.0 / value
	GameSettings.save_hud_config()


func _on_button_toggled(button_pressed: bool, button: CheckButton) -> void:
	var component := -1
	var key := ""
	match button:
		check_crosshair:
			component = HUD.Component.CROSSHAIR
			key = "crosshair"
		check_horizon:
			component = HUD.Component.HORIZON
			key = "horizon"
		check_ladder:
			component = HUD.Component.LADDER
			key = "ladder"
		check_speed:
			component = HUD.Component.SPEED
			key = "speed"
		check_altitude:
			component = HUD.Component.ALTITUDE
			key = "altitude"
		check_heading:
			component = HUD.Component.HEADING
			key = "heading"
		check_sticks:
			component = HUD.Component.STICKS
			key = "sticks"
		check_rpm:
			component = HUD.Component.RPM
			key = "rpm"
	hud.show_component(component, button_pressed)
	GameSettings.hud_config[key] = button_pressed
	GameSettings.save_hud_config()
