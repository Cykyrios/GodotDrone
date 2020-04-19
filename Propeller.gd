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


func _ready():
	if Engine.editor_hint:
		return
	
	diameter *= 0.0254
	pitch *= 0.0254
	
	set_visibility()
	
	ray.add_exception(get_parent())
	max_ray_length = ray.cast_to.length()


func set_clockwise(cw : bool):
	clockwise = cw
	set_visibility()


func set_visibility():
	$CW.visible = clockwise
	$CCW.visible = !clockwise


func get_thrust():
	var rot_speed = rpm * PI / 30.0 * radius
	return (pow(rot_speed, 2) * LIFT_RATIO / 1000) * (1 + 0 * 0.3 * get_ground_effect())


func get_ground_effect():
	var ground_effect = 0.0
	if ray.is_colliding():
		ray_length = -global_transform.xform_inv(ray.get_collision_point()).y
		ground_effect = 1 / (1 + pow(ray_length / max_ray_length, 2)) - 0.5
	else:
		ray_length = max_ray_length
#	print("ray: %8.3f gnd: %8.3f" % [ray_length, ground_effect])
	return ground_effect
