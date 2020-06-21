extends Spatial


var pause_menu = preload("res://GUI/PauseMenu.tscn")

var cameras = []
var camera_index = 0
var camera : Camera

onready var drone = $Drone
onready var radio_controller = $RadioController

var tracks = []


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
	if camera is FPVCamera and Graphics.graphics_settings["fisheye_mode"] != Graphics.FisheyeMode.OFF:
		camera.render_quad.visible = false
	camera = cameras[camera_index]
	camera.current = true
	if camera is FPVCamera and Graphics.graphics_settings["fisheye_mode"] != Graphics.FisheyeMode.OFF:
		camera.render_quad.visible = true
	camera.visible = true
	
	if camera_index == 1:
		drone.hud.visible = true
	else:
		drone.hud.visible = false


func _on_drone_reset():
	for track in tracks:
		track.reset_track()


func _on_resume():
	if pause_menu.can_resume:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		pause_menu.visible = false
		get_tree().paused = false


func _on_return_to_menu():
	var _discard = get_tree().change_scene("res://GUI/MainMenu.tscn")
	queue_free()
