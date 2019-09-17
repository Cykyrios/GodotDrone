extends Control
class_name HUD

# HUD components
onready var ladder = $VBoxContainer/HBoxContainer/HUDLadder
onready var speed_scale = $VBoxContainer/HBoxContainer/HUDSpeedScale
onready var altitude_scale = $VBoxContainer/HBoxContainer/HUDAltitudeScale
onready var heading_scale = $VBoxContainer/HUDHeadingScale

# Flight data
var delta = 0.0
var pitch = 0.0
var roll = 0.0
var heading = 0.0
var velocity = Vector3.ZERO
var altitude = 0.0


func _ready():
	update_hud(delta, pitch, roll, heading, velocity, altitude)


func update_hud(dt : float, p : float, r : float, h : float, v : Vector3, a : float):
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
