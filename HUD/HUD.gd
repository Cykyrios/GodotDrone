extends Control
class_name HUD

# HUD components
onready var ladder = $HBoxContainer/HUDLadder
onready var speed_scale = $HBoxContainer/HUDSpeedScale
onready var altitude_scale = $HBoxContainer/HUDAltitudeScale

# Flight data
var pitch = 0.0
var roll = 0.0
var heading = 0.0
var velocity = Vector3.ZERO
var altitude = 0.0

var t = 0.0


func _ready():
	update_hud()


func _process(delta):
	t += delta
	roll = sin(t)
	pitch = sin(1.2 * t) / 4
	velocity = Vector3(0.1 * sin(t), 0.2 * sin(1.2 * t), 30 + 10 * sin(0.3 * t))
	altitude = 50 + 70 * sin(t)
	update_hud()


func update_hud():
	ladder.update_ladder(pitch, roll)
	speed_scale.update_speed(velocity.length())
	altitude_scale.update_altitude(altitude)
