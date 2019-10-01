extends Control
class_name HUD

# HUD components
onready var ladder = $VBoxContainer/HBoxLadder/HUDLadder
onready var speed_scale = $VBoxContainer/HBoxLadder/HUDSpeedScale
onready var altitude_scale = $VBoxContainer/HBoxLadder/HUDAltitudeScale
onready var heading_scale = $VBoxContainer/HUDHeadingScale
onready var stick_left = $VBoxContainer/HBoxInput/HUDStickLeft
onready var stick_right = $VBoxContainer/HBoxInput/HUDStickRight

# Flight data
var delta = 0.0
var pitch = 0.0
var roll = 0.0
var heading = 0.0
var velocity = Vector3.ZERO
var altitude = 0.0
var left_stick = Vector2.ZERO
var right_stick = Vector2.ZERO


func _ready():
	update_hud(delta, pitch, roll, heading, velocity, altitude, left_stick, right_stick)


func update_hud(dt : float, p : float, r : float, h : float, v : Vector3, a : float,
		left_stick : Vector2, right_stick : Vector2):
	delta = dt
	pitch = p
	roll = r
	heading = h
	velocity = v
	altitude = a
	ladder.update_ladder(pitch, roll)
	speed_scale.update_speed(velocity.length(), delta)
	altitude_scale.update_altitude(altitude, delta)
	heading_scale.update_heading(heading, delta)
	stick_left.update_stick_input(left_stick)
	stick_right.update_stick_input(right_stick)
