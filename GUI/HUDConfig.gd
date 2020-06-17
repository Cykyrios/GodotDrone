extends HBoxContainer


onready var check_crosshair = $ScrollContainer/VBoxContainer/CheckCrosshair
onready var check_horizon = $ScrollContainer/VBoxContainer/CheckHorizon
onready var check_ladder = $ScrollContainer/VBoxContainer/CheckLadder
onready var check_speed = $ScrollContainer/VBoxContainer/CheckSpeed
onready var check_altitude = $ScrollContainer/VBoxContainer/CheckAltitude
onready var check_heading = $ScrollContainer/VBoxContainer/CheckHeading
onready var check_sticks = $ScrollContainer/VBoxContainer/CheckSticks
onready var check_rpm = $ScrollContainer/VBoxContainer/CheckRPM

onready var hud = $HUD


func _ready():
	var buttons := [check_crosshair, check_horizon, check_ladder, check_speed,
			check_altitude, check_heading, check_sticks, check_rpm]
	for button in buttons:
		button.connect("toggled", self, "_on_button_toggled", [button])


func _on_button_toggled(button_pressed: bool, button: CheckButton):
	match button:
		check_crosshair:
			hud.show_component(HUD.Component.CROSSHAIR, button_pressed)
		check_horizon:
			hud.show_component(HUD.Component.HORIZON, button_pressed)
		check_ladder:
			hud.show_component(HUD.Component.LADDER, button_pressed)
		check_speed:
			hud.show_component(HUD.Component.SPEED, button_pressed)
		check_altitude:
			hud.show_component(HUD.Component.ALTITUDE, button_pressed)
		check_heading:
			hud.show_component(HUD.Component.HEADING, button_pressed)
		check_sticks:
			hud.show_component(HUD.Component.STICKS, button_pressed)
		check_rpm:
			hud.show_component(HUD.Component.RPM, button_pressed)
