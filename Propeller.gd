tool
extends Spatial

class_name Propeller

onready var ray = $RayCast
var ray_length = 0.0
var max_ray_length = 0.0

export (float, 0.01, 0.5) var radius = 0.2
export (float, 0.0, 10.0) var LIFT_RATIO = 1.0
export (float, 0.5, 15) var diameter = 5
export (float, 0.5, 15) var pitch = 5
export (int, 2, 6) var num_blades = 2

var clockwise = false setget set_clockwise
var rpm = 0.0

var velocity = Vector3.ZERO setget set_velocity
var thrust = 0.0


func _ready():
	if Engine.editor_hint:
		return
	
	set_visibility()
	
	ray.add_exception(get_parent())
	max_ray_length = ray.cast_to.length()


func _physics_process(delta):
	if Engine.editor_hint:
		return
	
	var rot = rpm * PI / 30.0
	if clockwise:
		rot = -rot
	rotate_object_local(Vector3.UP, rot * delta)
	
	transform = transform.orthonormalized()


func set_clockwise(cw : bool):
	clockwise = cw
	set_visibility()


func set_visibility():
	$CW.visible = clockwise
	$CCW.visible = !clockwise


func set_velocity(vel : Vector3):
	velocity = vel


func get_thrust():
	var v0 = velocity.y
	# Dynamic thrust from ElectricAircraftGuy
	var d = diameter * 0.0254
	var p = pitch * 0.0254
	var area = PI * pow(d, 2) / 4.0
	var ve = rpm * p / 60.0
	thrust = 1.225 * area * (pow(ve, 2) - ve * v0) * pow(d / p / 3.29546, 1.5) * 1.5
	
	return thrust


func get_ground_effect():
	var ground_effect = 0.0
	if ray.is_colliding():
		ray_length = -global_transform.xform_inv(ray.get_collision_point()).y
		ground_effect = 1 / (1 + pow(ray_length / max_ray_length, 2)) - 0.5
	else:
		ray_length = max_ray_length
#	print("ray: %8.3f gnd: %8.3f" % [ray_length, ground_effect])
	return ground_effect
