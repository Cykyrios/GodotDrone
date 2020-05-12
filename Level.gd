extends Spatial


var pause_menu = preload("res://GUI/PauseMenu.tscn")

var cameras = []
var camera_index = 0
var camera : Camera

onready var drone = $Drone
onready var hud = $HUD
onready var radio_controller = $RadioController

var tracks = []

signal quit_to_menu


func _ready():
	cameras.append($FollowCamera)
	cameras.append($Drone/FPVCamera)
	cameras.append($CameraFixed)
	cameras.append($FlyaroundCamera/RotationHelper/Camera)
	
	camera = cameras[camera_index]
	
	change_camera()
	
	for c in get_children():
		if c is Track:
			tracks.append(c)
	
	radio_controller.connect("reset_requested", self, "_on_drone_reset")
	
	pause_menu = pause_menu.instance()
	add_child(pause_menu)
	pause_menu.visible = false
	pause_menu.connect("resumed", self, "_on_resume")
	pause_menu.connect("menu", self, "_on_return_to_menu")


func _process(delta):
	var fc = $Drone/FlightController
	var angles = fc.angles
	var velocity = fc.lin_vel
	var position = fc.pos
	var input = fc.input
	var left_stick = Vector2(input[1], -2 * (input[0] - 0.5))
	var right_stick = Vector2(input[2], input[3])
	var rpm = [fc.motors[0].rpm, fc.motors[1].rpm, fc.motors[2].rpm, fc.motors[3].rpm]
	hud.update_hud_data(delta, position, angles, velocity, left_stick, right_stick, rpm)


func _input(event):
	if event.is_action_pressed("change_camera"):
		camera_index += 1
		if camera_index >= cameras.size():
			camera_index = 0
		change_camera()
	
	if Input.is_action_just_pressed("pause_menu"):
		if !get_tree().paused:
			get_tree().paused = true
			pause_menu.visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif pause_menu.visible:
			pause_menu.emit_signal("resumed")


func change_camera():
	camera.visible = false
	camera.current = false
	if camera is FPVCamera:
		camera.render_quad.visible = false
	camera = cameras[camera_index]
	camera.current = true
	if camera is FPVCamera:
		camera.render_quad.visible = true
	camera.visible = true
	
	if camera_index == 1:
		hud.visible = true
	else:
		hud.visible = false


func _on_drone_reset():
	for track in tracks:
		track.reset_track()


func _on_resume():
	if pause_menu.can_resume:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		pause_menu.visible = false
		get_tree().paused = false


func _on_return_to_menu():
	get_tree().change_scene("res://GUI/MainMenu.tscn")
	queue_free()
