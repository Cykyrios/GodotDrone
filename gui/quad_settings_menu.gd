extends Control


signal back


@onready var camera_angle_slider := %CameraAngleSlider as HSlider
@onready var camera_angle_label := %CameraAngleCurrent as Label
@onready var dry_weight_slider := %DryWeightSlider as HSlider
@onready var dry_weight_label := %DryWeightCurrent as Label
@onready var battery_weight_slider := %BatteryWeightSlider as HSlider
@onready var battery_weight_label := %BatteryWeightCurrent as Label

@onready var rates_curve_list := %RatesCurveOptionButton as OptionButton
@onready var rate_label := %RateLabel as Label
@onready var rc_label := %RcLabel as Label
@onready var expo_label := %ExpoLabel as Label

@onready var pitch_rate_slider := %PitchRateSlider as HSlider
@onready var roll_rate_slider := %RollRateSlider as HSlider
@onready var yaw_rate_slider := %YawRateSlider as HSlider
@onready var pitch_rate_label := %PitchRate as Label
@onready var roll_rate_label := %RollRate as Label
@onready var yaw_rate_label := %YawRate as Label
@onready var pitch_rc_slider := %PitchRcSlider as HSlider
@onready var roll_rc_slider := %RollRcSlider as HSlider
@onready var yaw_rc_slider := %YawRcSlider as HSlider
@onready var pitch_rc_label := %PitchRc as Label
@onready var roll_rc_label := %RollRc as Label
@onready var yaw_rc_label := %YawRc as Label
@onready var pitch_expo_slider := %PitchExpoSlider as HSlider
@onready var roll_expo_slider := %RollExpoSlider as HSlider
@onready var yaw_expo_slider := %YawExpoSlider as HSlider
@onready var pitch_expo_label := %PitchExpo as Label
@onready var roll_expo_label := %RollExpo as Label
@onready var yaw_expo_label := %YawExpo as Label

@onready var rate_graph := %RateGraph as Control

@onready var button_reset_quad := %ButtonResetQuad as Button
@onready var button_reset_rates := %ButtonResetRates as Button
@onready var button_back := %ButtonBack as Button


func _ready() -> void:
	QuadSettings.load_quad_settings()

	var _discard := camera_angle_slider.value_changed.connect(_on_angle_changed)
	camera_angle_slider.value = QuadSettings.angle

	_discard = dry_weight_slider.value_changed.connect(_on_dry_weight_changed)
	_discard = battery_weight_slider.value_changed.connect(_on_battery_weight_changed)
	dry_weight_slider.value = QuadSettings.dry_weight * 1000
	battery_weight_slider.value = QuadSettings.battery_weight * 1000

	rates_curve_list.clear()
	for item: String in ControlProfile.RateCurve.keys():
		rates_curve_list.add_item(item)
	rates_curve_list.select(QuadSettings.control_profile.rate_curve)
	_discard = rates_curve_list.item_selected.connect(_on_rate_curve_selected)

	_discard = pitch_rate_slider.value_changed.connect(_on_rate_changed.bind(pitch_rate_slider))
	_discard = roll_rate_slider.value_changed.connect(_on_rate_changed.bind(roll_rate_slider))
	_discard = yaw_rate_slider.value_changed.connect(_on_rate_changed.bind(yaw_rate_slider))
	_discard = pitch_rc_slider.value_changed.connect(_on_rc_changed.bind(pitch_rc_slider))
	_discard = roll_rc_slider.value_changed.connect(_on_rc_changed.bind(roll_rc_slider))
	_discard = yaw_rc_slider.value_changed.connect(_on_rc_changed.bind(yaw_rc_slider))
	_discard = pitch_expo_slider.value_changed.connect(_on_expo_changed.bind(pitch_expo_slider))
	_discard = roll_expo_slider.value_changed.connect(_on_expo_changed.bind(roll_expo_slider))
	_discard = yaw_expo_slider.value_changed.connect(_on_expo_changed.bind(yaw_expo_slider))
	pitch_rate_slider.value = QuadSettings.control_profile.pitch_rate
	roll_rate_slider.value = QuadSettings.control_profile.roll_rate
	yaw_rate_slider.value = QuadSettings.control_profile.yaw_rate
	pitch_rc_slider.value = QuadSettings.control_profile.pitch_rc
	roll_rc_slider.value = QuadSettings.control_profile.roll_rc
	yaw_rc_slider.value = QuadSettings.control_profile.yaw_rc
	pitch_expo_slider.value = QuadSettings.control_profile.pitch_expo
	roll_expo_slider.value = QuadSettings.control_profile.roll_expo
	yaw_expo_slider.value = QuadSettings.control_profile.yaw_expo
	pitch_rate_label.custom_minimum_size.x = pitch_rate_label.size.x
	roll_rate_label.custom_minimum_size.x = roll_rate_label.size.x
	yaw_rate_label.custom_minimum_size.x = yaw_rate_label.size.x
	pitch_rc_label.custom_minimum_size.x = pitch_rc_label.size.x
	roll_rc_label.custom_minimum_size.x = roll_rc_label.size.x
	yaw_rc_label.custom_minimum_size.x = yaw_rc_label.size.x
	pitch_expo_label.custom_minimum_size.x = pitch_expo_label.size.x
	roll_expo_label.custom_minimum_size.x = roll_expo_label.size.x
	yaw_expo_label.custom_minimum_size.x = yaw_expo_label.size.x

	_discard = button_reset_quad.pressed.connect(_on_reset_quad_pressed)
	_discard = button_reset_rates.pressed.connect(_on_reset_rates_pressed)
	_discard = button_back.pressed.connect(_on_back_pressed)

	update_rates_ui()


func _input(event: InputEvent) -> void:
	if event.is_action("ui_cancel") and event.is_pressed() and not event.is_echo():
		accept_event()
		QuadSettings.save_quad_settings()
		back.emit()


func _on_angle_changed(value: float) -> void:
	camera_angle_label.text = "%d deg" % [value as int]
	QuadSettings.angle = value as int


func _on_dry_weight_changed(value: float) -> void:
	dry_weight_label.text = "%d g" % [value as int]
	QuadSettings.dry_weight = value / 1000


func _on_battery_weight_changed(value: float) -> void:
	battery_weight_label.text = "%d g" % [value as int]
	QuadSettings.battery_weight = value / 1000


func _on_rate_curve_selected(idx: int) -> void:
	var new_curve := ControlProfile.RateCurve[rates_curve_list.get_item_text(idx)] as ControlProfile.RateCurve
	if new_curve != QuadSettings.control_profile.rate_curve:
		QuadSettings.control_profile.rate_curve = new_curve
		update_rates_ui()


func _on_rate_changed(value: float, slider: HSlider) -> void:
	var text := "%d" % [value as int]
	if slider == pitch_rate_slider:
		pitch_rate_label.text = text
		QuadSettings.control_profile.pitch_rate = value as int
	elif slider == roll_rate_slider:
		roll_rate_label.text = text
		QuadSettings.control_profile.roll_rate = value as int
	elif slider == yaw_rate_slider:
		yaw_rate_label.text = text
		QuadSettings.control_profile.yaw_rate = value as int
	update_graph()


func _on_rc_changed(value: float, slider: HSlider) -> void:
	var text := "%d" % [value as int]
	if slider == pitch_rc_slider:
		pitch_rc_label.text = text
		QuadSettings.control_profile.pitch_rc = value as int
	elif slider == roll_rc_slider:
		roll_rc_label.text = text
		QuadSettings.control_profile.roll_rc = value as int
	elif slider == yaw_rc_slider:
		yaw_rc_label.text = text
		QuadSettings.control_profile.yaw_rc = value as int
	update_graph()


func _on_expo_changed(value: float, slider: HSlider) -> void:
	var text := "%1.2f" % [value]
	if slider == pitch_expo_slider:
		pitch_expo_label.text = text
		QuadSettings.control_profile.pitch_expo = value
	elif slider == roll_expo_slider:
		roll_expo_label.text = text
		QuadSettings.control_profile.roll_expo = value
	elif slider == yaw_expo_slider:
		yaw_expo_label.text = text
		QuadSettings.control_profile.yaw_expo = value
	update_graph()


func update_graph() -> void:
	var pitch: Array[Vector2] = []
	var roll: Array[Vector2] = []
	var yaw: Array[Vector2] = []

	var num_points := 101
	for i in num_points:
		var input := (i / 50.0 - 1) as float
		var pitch_y := QuadSettings.control_profile.get_axis_command(ControlProfile.Axis.PITCH, input)
		var roll_y := QuadSettings.control_profile.get_axis_command(ControlProfile.Axis.ROLL, input)
		var yaw_y := QuadSettings.control_profile.get_axis_command(ControlProfile.Axis.YAW, input)
		pitch.append(Vector2(input, pitch_y))
		roll.append(Vector2(input, roll_y))
		yaw.append(Vector2(input, yaw_y))

	rate_graph.update_rates(pitch, roll, yaw)


func update_rates_labels() -> void:
	match QuadSettings.control_profile.rate_curve:
		ControlProfile.RateCurve.ACTUAL:
			rate_label.text = "Max Rate"
			rc_label.text = "Center Rate"
			expo_label.text = "Expo"
		ControlProfile.RateCurve.RACEFLIGHT:
			rate_label.text = "Rate"
			rc_label.text = "Acro+"
			expo_label.text = "Expo"
		ControlProfile.RateCurve.KISS:
			rate_label.text = "Rate"
			rc_label.text = "RC Rate"
			expo_label.text = "RC Curve"
		ControlProfile.RateCurve.QUICKRATES:
			rate_label.text = "Max Rate"
			rc_label.text = "RC Rate"
			expo_label.text = "Expo"


func update_rates_ui() -> void:
	update_rates_labels()
	update_slider_limits()
	update_sliders()
	update_graph()


func update_slider_limits() -> void:
	match QuadSettings.control_profile.rate_curve:
		ControlProfile.RateCurve.ACTUAL:
			pitch_rate_slider.min_value = 0
			pitch_rate_slider.max_value = 1800
			roll_rate_slider.min_value = 0
			roll_rate_slider.max_value = 1800
			yaw_rate_slider.min_value = 0
			yaw_rate_slider.max_value = 1800
			pitch_rc_slider.min_value = 10
			pitch_rc_slider.max_value = 1800
			roll_rc_slider.min_value = 10
			roll_rc_slider.max_value = 1800
			yaw_rc_slider.min_value = 10
			yaw_rc_slider.max_value = 1800
		ControlProfile.RateCurve.RACEFLIGHT:
			pitch_rate_slider.min_value = 10
			pitch_rate_slider.max_value = 1800
			roll_rate_slider.min_value = 10
			roll_rate_slider.max_value = 1800
			yaw_rate_slider.min_value = 10
			yaw_rate_slider.max_value = 1800
			pitch_rc_slider.min_value = 0
			pitch_rc_slider.max_value = 255
			roll_rc_slider.min_value = 0
			roll_rc_slider.max_value = 255
			yaw_rc_slider.min_value = 0
			yaw_rc_slider.max_value = 255
		ControlProfile.RateCurve.KISS:
			pitch_rate_slider.min_value = 0
			pitch_rate_slider.max_value = 99
			roll_rate_slider.min_value = 0
			roll_rate_slider.max_value = 99
			yaw_rate_slider.min_value = 0
			yaw_rate_slider.max_value = 99
			pitch_rc_slider.min_value = 1
			pitch_rc_slider.max_value = 255
			roll_rc_slider.min_value = 1
			roll_rc_slider.max_value = 255
			yaw_rc_slider.min_value = 1
			yaw_rc_slider.max_value = 255
		ControlProfile.RateCurve.QUICKRATES:
			pitch_rate_slider.min_value = 0
			pitch_rate_slider.max_value = 1800
			roll_rate_slider.min_value = 0
			roll_rate_slider.max_value = 1800
			yaw_rate_slider.min_value = 0
			yaw_rate_slider.max_value = 1800
			pitch_rc_slider.min_value = 1
			pitch_rc_slider.max_value = 255
			roll_rc_slider.min_value = 1
			roll_rc_slider.max_value = 255
			yaw_rc_slider.min_value = 1
			yaw_rc_slider.max_value = 255


func update_sliders() -> void:
	pitch_rate_slider.value = QuadSettings.control_profile.pitch_rate
	roll_rate_slider.value = QuadSettings.control_profile.roll_rate
	yaw_rate_slider.value = QuadSettings.control_profile.yaw_rate
	pitch_rc_slider.value = QuadSettings.control_profile.pitch_rc
	roll_rc_slider.value = QuadSettings.control_profile.roll_rc
	yaw_rc_slider.value = QuadSettings.control_profile.yaw_rc
	pitch_expo_slider.value = QuadSettings.control_profile.pitch_expo
	roll_expo_slider.value = QuadSettings.control_profile.roll_expo
	yaw_expo_slider.value = QuadSettings.control_profile.yaw_expo


func _on_reset_quad_pressed() -> void:
	QuadSettings.reset_quad()
	camera_angle_slider.value = QuadSettings.angle
	dry_weight_slider.value = QuadSettings.dry_weight * 1000
	battery_weight_slider.value = QuadSettings.battery_weight * 1000


func _on_reset_rates_pressed() -> void:
	QuadSettings.reset_rates()
	update_sliders()


func _on_back_pressed() -> void:
	QuadSettings.save_quad_settings()
	back.emit()
