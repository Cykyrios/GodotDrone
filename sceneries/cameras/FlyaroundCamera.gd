extends Node3D


@export var base_speed := 30.0 # (float, 0.1, 100)
@export var speed_modifier := 1.5
@export var look_around_speed := 1.0
@export var look_around_sensitivity := 0.1

var speed := 0.0
const MAX_SPEED := 300.0
const MIN_SPEED := 0.1

@onready var rotation_helper := $RotationHelper
@onready var camera := $RotationHelper/Camera3D


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	speed = base_speed


func _process(delta: float) -> void:
	var dir = Vector3.ZERO
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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_rot := Vector2(event.relative.x, event.relative.y)
		var rot_max := minf(deg_to_rad(mouse_rot.y * look_around_sensitivity) * sign(mouse_rot.y), look_around_speed)
		rotation_helper.rotate_x(rot_max * sign(mouse_rot.y) * -1)
		rot_max = minf(deg_to_rad(mouse_rot.x * look_around_sensitivity) * sign(mouse_rot.x), look_around_speed)
		self.rotate_y(rot_max * sign(mouse_rot.x) * -1)
		var camera_rot: Vector3 = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -89, 89)
		rotation_helper.rotation_degrees = camera_rot
