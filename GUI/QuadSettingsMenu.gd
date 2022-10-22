extends Control


signal back


@onready var camera_angle_slider := $%CameraAngleSlider as HSlider
@onready var camera_angle_label := $%CameraAngleCurrent as Label
@onready var dry_weight_slider := $%DryWeightSlider as HSlider
@onready var dry_weight_label := $%DryWeightCurrent as Label
@onready var battery_weight_slider := $%BatteryWeightSlider as HSlider
@onready var battery_weight_label := $%BatteryWeightCurrent as Label

@onready var rate_pitch_slider := $%PitchSlider as HSlider
@onready var rate_roll_slider := $%RollSlider as HSlider
@onready var rate_yaw_slider := $%YawSlider as HSlider
@onready var rate_pitch_label := $%PitchRate as Label
@onready var rate_roll_label := $%RollRate as Label
@onready var rate_yaw_label := $%YawRate as Label
@onready var expo_pitch_slider := $%PitchExpoSlider as HSlider
@onready var expo_roll_slider := $%RollExpoSlider as HSlider
@onready var expo_yaw_slider := $%YawExpoSlider as HSlider
@onready var expo_pitch_label := $%PitchExpo as Label
@onready var expo_roll_label := $%RollExpo as Label
@onready var expo_yaw_label := $%YawExpo as Label

@onready var rate_graph := $%RateGraph as Control

@onready var button_reset_quad := $%ButtonResetQuad as Button
@onready var button_reset_rates := $%ButtonResetRates as Button
@onready var button_back := $%ButtonBack as Button


func _ready() -> void:
	QuadSettings.load_quad_settings()

	var _discard = camera_angle_slider.value_changed.connect(_on_angle_changed)
	camera_angle_slider.value = QuadSettings.angle

	_discard = dry_weight_slider.value_changed.connect(_on_dry_weight_changed)
	_discard = battery_weight_slider.value_changed.connect(_on_battery_weight_changed)
	dry_weight_slider.value = QuadSettings.dry_weight * 1000
	battery_weight_slider.value = QuadSettings.battery_weight * 1000

	_discard = rate_pitch_slider.value_changed.connect(_on_rate_changed.bind(rate_pitch_slider))
	_discard = rate_roll_slider.value_changed.connect(_on_rate_changed.bind(rate_roll_slider))
	_discard = rate_yaw_slider.value_changed.connect(_on_rate_changed.bind(rate_yaw_slider))
	_discard = expo_pitch_slider.value_changed.connect(_on_expo_changed.bind(expo_pitch_slider))
	_discard = expo_roll_slider.value_changed.connect(_on_expo_changed.bind(expo_roll_slider))
	_discard = expo_yaw_slider.value_changed.connect(_on_expo_changed.bind(expo_yaw_slider))
	rate_pitch_slider.value = QuadSettings.rate_pitch
	rate_roll_slider.value = QuadSettings.rate_roll
	rate_yaw_slider.value = QuadSettings.rate_yaw
	expo_pitch_slider.value = QuadSettings.expo_pitch
	expo_roll_slider.value = QuadSettings.expo_roll
	expo_yaw_slider.value = QuadSettings.expo_yaw

	_discard = button_reset_quad.pressed.connect(_on_reset_quad_pressed)
	_discard = button_reset_rates.pressed.connect(_on_reset_rates_pressed)
	_discard = button_back.pressed.connect(_on_back_pressed)


func _input(event):
	if event.is_action("ui_cancel") and event.is_pressed() and not event.is_echo():
		accept_event()
		back.emit()


func _on_angle_changed(value: float) -> void:
	camera_angle_label.text = "%d deg" % [int(value)]
	QuadSettings.angle = int(value)


func _on_dry_weight_changed(value: float) -> void:
	dry_weight_label.text = "%d g" % [int(value)]
	QuadSettings.dry_weight = value / 1000


func _on_battery_weight_changed(value: float) -> void:
	battery_weight_label.text = "%d g" % [int(value)]
	QuadSettings.battery_weight = value / 1000


func _on_rate_changed(value: float, slider: HSlider) -> void:
	var text := "%d deg/s" % [int(value)]
	if slider == rate_pitch_slider:
		rate_pitch_label.text = text
		QuadSettings.rate_pitch = int(value)
	elif slider == rate_roll_slider:
		rate_roll_label.text = text
		QuadSettings.rate_roll = int(value)
	elif slider == rate_yaw_slider:
		rate_yaw_label.text = text
		QuadSettings.rate_yaw = int(value)
	update_graph()


func _on_expo_changed(value: float, slider: HSlider) -> void:
	var text := "Expo %1.2f" % [value]
	if slider == expo_pitch_slider:
		expo_pitch_label.text = text
		QuadSettings.expo_pitch = value
	elif slider == expo_roll_slider:
		expo_roll_label.text = text
		QuadSettings.expo_roll = value
	elif slider == expo_yaw_slider:
		expo_yaw_label.text = text
		QuadSettings.expo_yaw = value
	update_graph()


func update_graph() -> void:
	rate_graph.update_rates(
			Vector3(rate_pitch_slider.value, rate_roll_slider.value, rate_yaw_slider.value),
			Vector3(expo_pitch_slider.value, expo_roll_slider.value, expo_yaw_slider.value)
	)


func _on_reset_quad_pressed() -> void:
	QuadSettings.reset_quad()
	camera_angle_slider.value = QuadSettings.angle
	dry_weight_slider.value = QuadSettings.dry_weight * 1000
	battery_weight_slider.value = QuadSettings.battery_weight * 1000


func _on_reset_rates_pressed() -> void:
	QuadSettings.reset_rates()
	rate_pitch_slider.value = QuadSettings.rate_pitch
	rate_roll_slider.value = QuadSettings.rate_roll
	rate_yaw_slider.value = QuadSettings.rate_yaw
	expo_pitch_slider.value = QuadSettings.expo_pitch
	expo_roll_slider.value = QuadSettings.expo_roll
	expo_yaw_slider.value = QuadSettings.expo_yaw


func _on_back_pressed() -> void:
	QuadSettings.save_quad_settings()
	back.emit()
