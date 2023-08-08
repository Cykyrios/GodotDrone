extends Node3D


var packed_pause_menu := preload("res://GUI/PauseMenu.tscn")
var pause_menu: PauseMenu = null

var cameras := []
var camera_index := 0
var camera: Camera3D = null

@onready var drone := $Drone
@onready var radio_controller := $RadioController

var tracks := []


func _ready() -> void:
	cameras = get_cameras(self)
	for c in cameras:
		if c.name == "FPVCamera":
			camera_index = cameras.find(c)
#	camera = cameras[camera_index]
	camera = cameras[0]
	camera_index = 1
	change_camera()

	for c in get_children():
		if c is Track:
			tracks.append(c)
	var _discard = Global.game_mode_changed.connect(_on_game_mode_changed)

	_discard = drone.respawned.connect(_on_drone_reset)
	


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("change_camera"):
		camera_index += 1
		if camera_index >= cameras.size():
			camera_index = 0
		change_camera()

	if event.is_action("pause_menu") and event.is_pressed() and not event.is_echo():
		if not get_tree().paused:
			get_tree().paused = true
			add_pause_menu()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func get_cameras(node: Node) -> Array:
	var cams := []
	for child in node.get_children():
		if child is Camera3D:
			cams.append(child)
		if not child is FPVCamera:
			cams.append_array(get_cameras(child))
	return cams


func change_camera() -> void:
	camera.visible = false
	camera.current = false
	if camera is FPVCamera and Graphics.graphics_settings["fisheye_mode"] != Graphics.FisheyeMode.OFF:
		camera.render_quad.visible = false
	camera = cameras[camera_index]
	camera.current = true
	if camera is FPVCamera and Graphics.graphics_settings["fisheye_mode"] != Graphics.FisheyeMode.OFF:
		camera.render_quad.visible = true
	camera.visible = true


func add_pause_menu() -> void:
	pause_menu = packed_pause_menu.instantiate()
	add_child(pause_menu)
	var _discard = pause_menu.resumed.connect(_on_resume)
	_discard = pause_menu.menu.connect(_on_return_to_menu)
	_discard = pause_menu.resumed.connect(func(): pause_menu.queue_free())


func _on_drone_reset() -> void:
	for track in tracks:
		track.reset_track()
	if Global.game_mode == Global.GameMode.RACE and Global.active_track:
		Global.active_track.initialize_replay(drone)
		Global.active_track.load_replays()
		Global.active_track.start_countdown()


func _on_resume() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pause_menu.queue_free()
	await get_tree().process_frame
	get_tree().paused = false


func _on_return_to_menu() -> void:
	var _discard = get_tree().change_scene_to_file("res://GUI/MainMenu.tscn")
	queue_free()


func _on_game_mode_changed(mode: int) -> void:
	if mode == Global.GameMode.FREE or tracks.is_empty():
		if Global.active_track:
			Global.active_track.stop_race()
			Global.active_track.stop_recording_replay()
		Global.active_track = null
	elif mode == Global.GameMode.RACE:
		Global.active_track = get_closest_track()
		drone.reset()


func get_closest_track() -> Track:
	var has_launchpad := false
	var closest_idx := 0
	var new_idx := -1
	var closest_distance := 9999.9
	var new_distance := 0.0
	if tracks.is_empty():
		return null
	for track in tracks:
		new_idx += 1
		if not track.has_launchpad:
			continue
		has_launchpad = true
		for launch_pos in track.launch_areas:
			new_distance = (launch_pos.global_transform.origin - drone.global_transform.origin).length()
			if new_distance < closest_distance:
				closest_distance = new_distance
				closest_idx = new_idx
	if has_launchpad:
		return tracks[closest_idx]
	return null
