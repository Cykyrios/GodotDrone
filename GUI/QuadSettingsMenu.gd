extends Control


signal back


@onready var angle_slider := $PanelContainer/VBoxContainer/SettingsHBox/QuadScroll/Quad/AngleSlider
@onready var angle_label := $PanelContainer/VBoxContainer/SettingsHBox/QuadScroll/Quad/AngleCurrent
@onready var dry_weight_slider := $PanelContainer/VBoxContainer/SettingsHBox/QuadScroll/Quad/DryWeightSlider
@onready var dry_weight_label := $PanelContainer/VBoxContainer/SettingsHBox/QuadScroll/Quad/DryWeightCurrent
@onready var battery_weight_slider := $PanelContainer/VBoxContainer/SettingsHBox/QuadScroll/Quad/BatteryWeightSlider
@onready var battery_weight_label := $PanelContainer/VBoxContainer/SettingsHBox/QuadScroll/Quad/BatteryWeightCurrent

@onready var rate_pitch_slider := $PanelContainer/VBoxContainer/SettingsHBox/RatesScroll/Rates/RateAdjust/PitchSlider
@onready var rate_roll_slider := $PanelContainer/VBoxContainer/SettingsHBox/RatesScroll/Rates/RateAdjust/RollSlider
@onready var rate_yaw_slider := $PanelContainer/VBoxContainer/SettingsHBox/RatesScroll/Rates/RateAdjust/YawSlider
@onready var rate_pitch_label := $PanelContainer/VBoxContainer/SettingsHBox/RatesScroll/Rates/RateAdjust/PitchRate
@onready var rate_roll_label := $PanelContainer/VBoxContainer/SettingsHBox/RatesScroll/Rates/RateAdjust/RollRate
@onready var rate_yaw_label := $PanelContainer/VBoxContainer/SettingsHBox/RatesScroll/Rates/RateAdjust/YawRate
@onready var expo_pitch_slider := $PanelContainer/VBoxContainer/SettingsHBox/RatesScroll/Rates/RateAdjust/PitchExpoSlider
@onready var expo_roll_slider := $PanelContainer/VBoxContainer/SettingsHBox/RatesScroll/Rates/RateAdjust/RollExpoSlider
@onready var expo_yaw_slider := $PanelContainer/VBoxContainer/SettingsHBox/RatesScroll/Rates/RateAdjust/YawExpoSlider
@onready var expo_pitch_label := $PanelContainer/VBoxContainer/SettingsHBox/RatesScroll/Rates/RateAdjust/PitchExpo
@onready var expo_roll_label := $PanelContainer/VBoxContainer/SettingsHBox/RatesScroll/Rates/RateAdjust/RollExpo
@onready var expo_yaw_label := $PanelContainer/VBoxContainer/SettingsHBox/RatesScroll/Rates/RateAdjust/YawExpo

@onready var rate_graph := $PanelContainer/VBoxContainer/SettingsHBox/RatesScroll/Rates/RateGraph


func _ready() -> void:
	QuadSettings.load_quad_settings()

	var _discard = angle_slider.value_changed.connect(_on_angle_changed)
	angle_slider.value = QuadSettings.angle

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

	_discard = $PanelContainer/VBoxContainer/ButtonsHBox/ButtonResetQuad.pressed.connect(_on_reset_quad_pressed)
	_discard = $PanelContainer/VBoxContainer/ButtonsHBox/ButtonResetRates.pressed.connect(_on_reset_rates_pressed)
	_discard = $PanelContainer/VBoxContainer/ButtonsHBox/ButtonBack.pressed.connect(_on_back_pressed)


func _input(event):
	if event.is_action("ui_cancel") and event.is_pressed() and not event.is_echo():
		accept_event()
		back.emit()


func _on_angle_changed(value: float) -> void:
	angle_label.text = "%d deg" % int(value)
	QuadSettings.angle = int(value)


func _on_dry_weight_changed(value: float) -> void:
	dry_weight_label.text = "%d g" % int(value)
	QuadSettings.dry_weight = value / 1000


func _on_battery_weight_changed(value: float) -> void:
	battery_weight_label.text = "%d g" % int(value)
	QuadSettings.battery_weight = value / 1000


func _on_rate_changed(value: float, slider: HSlider) -> void:
	var text := "%d deg/s" % int(value)
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
	var text := "Expo %1.2f" % value
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
	rate_graph.update_rates(Vector3(rate_pitch_slider.value, rate_roll_slider.value, rate_yaw_slider.value),
			Vector3(expo_pitch_slider.value, expo_roll_slider.value, expo_yaw_slider.value))


func _on_reset_quad_pressed() -> void:
	QuadSettings.reset_quad()
	angle_slider.value = QuadSettings.angle
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
