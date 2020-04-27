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
var use_blur = false
export (Color) var color = Color(1.0, 1.0, 1.0, 1.0) setget set_color
export (float, 1, 3) var prop_disk_alpha = 1.0 setget set_prop_disk_alpha
export (float, 0, 2) var prop_disk_emission = 0.0 setget set_prop_disk_emission
export (int, 1, 20) var prop_disk_falloff = 10 setget set_prop_disk_falloff

var velocity = Vector3.ZERO setget set_velocity
var thrust = 0.0


func _ready():
	if Engine.editor_hint:
		return
	
	set_visibility(true)
	$PropBlurDisk.visible = false
	
	ray.add_exception(get_parent())
	max_ray_length = ray.cast_to.length()


func _process(delta):
	if Engine.editor_hint:
		return
	
	if rpm > 500:
		if !use_blur:
			use_blur = true
			$PropBlurDisk.visible = true
			set_visibility(false)
	else:
		if use_blur:
			use_blur = false
			$PropBlurDisk.visible = false
			set_visibility(true)


func set_clockwise(cw : bool):
	clockwise = cw
	set_visibility(true)


func set_visibility(show_prop : bool):
	if show_prop:
		$CW.visible = clockwise
		$CCW.visible = !clockwise
	else:
		$CW.visible = false
		$CCW.visible = false


func set_color(col : Color):
	color = col
	$CW.mesh.surface_get_material(0).set_shader_param("propeller_color", color)
	$CCW.mesh.surface_get_material(0).set_shader_param("propeller_color", color)
	$PropBlurDisk.mesh.surface_get_material(0).set_shader_param("propeller_color", color)


func set_prop_disk_alpha(alpha : float):
	prop_disk_alpha = alpha
	$PropBlurDisk.mesh.surface_get_material(0).set_shader_param("alpha_boost", prop_disk_alpha)


func set_prop_disk_emission(emission : float):
	prop_disk_emission = emission
	$PropBlurDisk.mesh.surface_get_material(0).set_shader_param("emission_power", prop_disk_emission)


func set_prop_disk_falloff(falloff : float):
	prop_disk_falloff = falloff
	$PropBlurDisk.mesh.surface_get_material(0).set_shader_param("emission_falloff", prop_disk_falloff)


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
