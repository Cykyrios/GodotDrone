extends Spatial

export(float, 0.1, 100) var base_speed := 30.0
export var speed_modifier := 1.5
export var look_around_speed := 1.0
export var look_around_sensitivity := 0.1

var speed: float
const MAX_SPEED: float = 300.0
const MIN_SPEED: float = 0.1

var rotation_helper
var camera


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	rotation_helper = $RotationHelper
	camera = $RotationHelper/Camera
	
	speed = base_speed


func _process(delta):
	var dir = Vector3()
	if Input.is_action_pressed("camera_forward"):
		dir.z -= 1
	if Input.is_action_pressed("camera_backward"):
		dir.z += 1
	if Input.is_action_pressed("camera_left"):
		dir.x -= 1
	if Input.is_action_pressed("camera_right"):
		dir.x += 1
	if Input.is_action_pressed("camera_up"):
		dir.y += 1
	if Input.is_action_pressed("camera_down"):
		dir.y -= 1
	
	if Input.is_action_pressed("camera_speed_up"):
		speed += speed * speed_modifier * delta
	elif Input.is_action_pressed("camera_speed_down"):
		speed -= speed * speed_modifier * delta
	speed = clamp(speed, MIN_SPEED, MAX_SPEED)
	
	# retrieve rotation_helper basis?
	dir = dir.normalized()
	self.translate_object_local(dir * speed * delta)


func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_rot = Vector2(event.relative.x, event.relative.y)
		var rot_max = min(deg2rad(mouse_rot.y * look_around_sensitivity) * sign(mouse_rot.y), look_around_speed)
		rotation_helper.rotate_x(rot_max * sign(mouse_rot.y) * -1)
		rot_max = min(deg2rad(mouse_rot.x * look_around_sensitivity) * sign(mouse_rot.x), look_around_speed)
		self.rotate_y(rot_max * sign(mouse_rot.x) * -1)
		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -89, 89)
		rotation_helper.rotation_degrees = camera_rot
