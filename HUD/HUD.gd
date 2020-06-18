extends Control
class_name HUD


enum Component {CROSSHAIR, STATUS, HEADING, SPEED, ALTITUDE, LADDER, HORIZON, STICKS, RPM}

# HUD components
onready var ladder = $VBoxContainer/HBoxLadder/HUDLadder
onready var speed_scale = $VBoxContainer/HBoxLadder/HUDSpeedScale
onready var altitude_scale = $VBoxContainer/HBoxLadder/HUDAltitudeScale
onready var heading_scale = $VBoxContainer/HUDHeadingScale
onready var stick_left = $VBoxContainer/HBoxInput/HUDStickLeft
onready var stick_right = $VBoxContainer/HBoxInput/HUDStickRight
onready var rpm_table = $HUDRPM
onready var status = $HUDStatus

# Flight data
var hud_timer = 0.1
var hud_delta = 0.0
var hud_position = Vector3.ZERO
var hud_angles = Vector3.ZERO
var hud_velocity = Vector3.ZERO
var hud_left_stick = Vector2.ZERO
var hud_right_stick = Vector2.ZERO
var hud_rpm = [0, 0, 0, 0]
var is_first = false
var first_angles = Vector3.ZERO


func _ready():
	reset_data()
	update_data(hud_delta, hud_position, hud_angles, hud_velocity, hud_left_stick, hud_right_stick, hud_rpm)


func _process(delta):
	if hud_delta >= hud_timer:
		hud_position /= hud_delta
		hud_angles /= hud_delta
		hud_velocity /= hud_delta
		hud_left_stick /= hud_delta
		hud_right_stick /= hud_delta
		for i in range(hud_rpm.size()):
			hud_rpm[i] /= hud_delta
		update_display()
		reset_data()


func show_component(component: int, show: bool = true):
	var self_only := false
	var mod := Color(1, 1, 1, 1)
	if not show:
		mod = Color(1, 1, 1, 0)
	var hud_component := []
	match component:
		Component.CROSSHAIR:
			hud_component.append($Crosshair)
		Component.STATUS:
			hud_component.append(status)
		Component.HEADING:
			hud_component.append(heading_scale)
		Component.SPEED:
			hud_component.append(speed_scale)
		Component.ALTITUDE:
			hud_component.append(altitude_scale)
		Component.LADDER:
			for marker in ladder.pitch_markers:
				hud_component.append(marker)
		Component.HORIZON:
			hud_component.append(ladder.horizon)
			self_only = true
		Component.STICKS:
			hud_component.append(stick_left)
			hud_component.append(stick_right)
		Component.RPM:
			hud_component.append(rpm_table)
	for comp in hud_component:
		if self_only:
			comp.self_modulate = mod
		else:
			comp.modulate = mod


func update_display():
	ladder.update_ladder(hud_angles.x, hud_angles.z)
	speed_scale.update_speed(hud_velocity.length(), hud_delta)
	altitude_scale.update_altitude(hud_position.y, hud_delta)
	heading_scale.update_heading(hud_angles.y, hud_delta)
	stick_left.update_stick_input(hud_left_stick)
	stick_right.update_stick_input(hud_right_stick)
	rpm_table.update_rpm(hud_rpm[0], hud_rpm[1], hud_rpm[2], hud_rpm[3])


func update_data(dt : float, position : Vector3, angles : Vector3, velocity : Vector3,
		left_stick : Vector2, right_stick : Vector2, rpm):
	hud_delta += dt
	hud_position += dt * position
	if is_first:
		first_angles = angles
		is_first = false
	# Adjust angles to prevent averaging issues
	hud_angles += dt * get_adjusted_angles(angles)
	hud_velocity += dt * velocity
	hud_left_stick += dt * left_stick
	hud_right_stick += dt * right_stick
	for i in range(hud_rpm.size()):
		hud_rpm[i] += dt * rpm[i]


func reset_data():
	is_first = true
	first_angles = Vector3.ZERO
	hud_delta = 0.0
	hud_position = Vector3.ZERO
	hud_angles = Vector3.ZERO
	hud_velocity = Vector3.ZERO
	hud_left_stick = Vector2.ZERO
	hud_right_stick = Vector2.ZERO
	hud_rpm = [0, 0, 0, 0]


func get_adjusted_angles(angles : Vector3):
	var result = angles
	var correction = 0
	
	for i in range(3):
		# Check sign changes by difference with PI as arbitrary threshold
		if abs(angles[i] - first_angles[i]) > PI:
			if first_angles[i] > 0:
				correction = 1
			else:
				correction = -1
			result[i] = angles[i] + 2 * PI * correction
	
	return result
