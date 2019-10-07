extends Spatial

var cameras = []
var camera_index = 0
var camera : Camera

onready var hud = $HUD

# Called when the node enters the scene tree for the first time.
func _ready():
	cameras.append($FollowCamera)
	cameras.append($Drone/CameraFPV)
	cameras.append($CameraFixed)
	cameras.append($FlyaroundCamera/RotationHelper/Camera)
	
	camera = cameras[camera_index]
	
	change_camera()


func _process(delta):
	var fc = $Drone/FlightController
	var angles = fc.angles
	var velocity = fc.lin_vel
	var altitude = fc.pos.y
	var input = fc.input
	var left_stick = Vector2(input[1], -input[0])
	var right_stick = Vector2(input[2], input[3])
	var rpm = [fc.motors[0].rpm, fc.motors[1].rpm, fc.motors[2].rpm, fc.motors[3].rpm]
	hud.update_hud(delta, angles.x, angles.z, angles.y, velocity, altitude, left_stick, right_stick, rpm)


func _input(event):
	if event.is_action_pressed("change_camera"):
		camera_index += 1
		if camera_index >= cameras.size():
			camera_index = 0
		change_camera()
	
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = !get_tree().paused


func change_camera():
	camera.current = false
	camera = cameras[camera_index]
	camera.current = true
	
	if camera_index == 1:
		hud.visible = true
	else:
		hud.visible = false
