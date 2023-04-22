extends HBoxContainer


@onready var fps := %SpinBoxRefreshRate as SpinBox
@onready var check_crosshair := %CheckCrosshair as CheckButton
@onready var check_horizon := %CheckHorizon as CheckButton
@onready var check_ladder := %CheckLadder as CheckButton
@onready var check_speed := %CheckSpeed as CheckButton
@onready var check_altitude := %CheckAltitude as CheckButton
@onready var check_heading := %CheckHeading as CheckButton
@onready var check_sticks := %CheckSticks as CheckButton
@onready var check_rpm := %CheckRPM as CheckButton

@onready var hud := %HUD as Control


func _ready() -> void:
	GameSettings.load_hud_config()
	var _discard = fps.value_changed.connect(_on_hud_fps_changed)
	fps.value = GameSettings.hud_config["fps"]
	var buttons := [check_crosshair, check_horizon, check_ladder, check_speed,
			check_altitude, check_heading, check_sticks, check_rpm]
	for button in buttons:
		_discard = button.toggled.connect(_on_button_toggled.bind(button))
		if button == check_crosshair:
			button.button_pressed = GameSettings.hud_config["crosshair"]
			hud.show_component(HUD.Component.CROSSHAIR, button.button_pressed)
		elif button == check_horizon:
			button.button_pressed = GameSettings.hud_config["horizon"]
			hud.show_component(HUD.Component.HORIZON, button.button_pressed)
		elif button == check_ladder:
			button.button_pressed = GameSettings.hud_config["ladder"]
			hud.show_component(HUD.Component.LADDER, button.button_pressed)
		elif button == check_speed:
			button.button_pressed = GameSettings.hud_config["speed"]
			hud.show_component(HUD.Component.SPEED, button.button_pressed)
		elif button == check_altitude:
			button.button_pressed = GameSettings.hud_config["altitude"]
			hud.show_component(HUD.Component.ALTITUDE, button.button_pressed)
		elif button == check_heading:
			button.button_pressed = GameSettings.hud_config["heading"]
			hud.show_component(HUD.Component.HEADING, button.button_pressed)
		elif button == check_sticks:
			button.button_pressed = GameSettings.hud_config["sticks"]
			hud.show_component(HUD.Component.STICKS, button.button_pressed)
		elif button == check_rpm:
			button.button_pressed = GameSettings.hud_config["rpm"]
			hud.show_component(HUD.Component.RPM, button.button_pressed)


func _on_hud_fps_changed(value: float) -> void:
	GameSettings.hud_config["fps"] = int(value)
	hud.hud_timer = 1.0 / value
	GameSettings.save_hud_config()


func _on_button_toggled(button_pressed: bool, button: CheckButton) -> void:
	var component := -1
	var key := ""
	if button == check_crosshair:
		component = HUD.Component.CROSSHAIR
		key = "crosshair"
	elif button == check_horizon:
		component = HUD.Component.HORIZON
		key = "horizon"
	elif button == check_ladder:
		component = HUD.Component.LADDER
		key = "ladder"
	elif button == check_speed:
		component = HUD.Component.SPEED
		key = "speed"
	elif button == check_altitude:
		component = HUD.Component.ALTITUDE
		key = "altitude"
	elif button == check_heading:
		component = HUD.Component.HEADING
		key = "heading"
	elif button == check_sticks:
		component = HUD.Component.STICKS
		key = "sticks"
	elif button == check_rpm:
		component = HUD.Component.RPM
		key = "rpm"
	hud.show_component(component, button_pressed)
	GameSettings.hud_config[key] = button_pressed
	GameSettings.save_hud_config()
