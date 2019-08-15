extends Spatial

var cameras = []
var camera_index = 0
var camera : Camera

# Called when the node enters the scene tree for the first time.
func _ready():
	cameras.append($CameraFollow)
	cameras.append($Drone/CameraFPV)
	cameras.append($CameraFixed)
	
	camera = cameras[camera_index]
	
	change_camera()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _input(event):
	if event.is_action_pressed("change_camera"):
		camera_index += 1
		if camera_index >= cameras.size():
			camera_index = 0
		change_camera()


func change_camera():
	camera.current = false
	camera = cameras[camera_index]
	camera.current = true
