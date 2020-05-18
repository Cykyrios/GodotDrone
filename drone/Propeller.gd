tool
extends Spatial

class_name Propeller

onready var cw = $CW
onready var ccw = $CCW
onready var prop_disk = $PropBlurDisk

onready var ray = $RayCast
var ray_length = 0.0
var max_ray_length = 0.0

export (float, 0.5, 15) var diameter = 5
export (float, 0.5, 15) var pitch = 5
export (int, 2, 6) var num_blades = 2
export (float, 0.0, 0.1) var c_tip = 0.01
export (float, 0.0, 10.0) var cl0 = 0.1
export (float, 0.0, 10.0) var cla = 0.1
export (float, 0.0, 10.0) var cd0 = 0.1
export (float, 0.0, 10.0) var cda = 0.1
export (float, 0.0, 10.0) var cm0 = 0.1
export (float, 0.0, 10.0) var cma = 0.1
export (float, 0.0, 10.0) var disk_delta = 0.2

var clockwise = false setget set_clockwise
var rpm = 0.0
var use_blur = false
export (Color) var color = Color(1.0, 1.0, 1.0, 1.0) setget set_color
export (float, 1, 3) var prop_disk_alpha = 1.0 setget set_prop_disk_alpha
export (float, 0, 2) var prop_disk_emission = 0.0 setget set_prop_disk_emission
export (int, 1, 20) var prop_disk_falloff = 10 setget set_prop_disk_falloff

var velocity = Vector3.ZERO setget set_velocity
var forces = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]

var radius = diameter * 0.0254 / 2.0
var theta_tip = 1.25 * pitch / (PI * diameter)
var w = 0.0

var debug = 0


func _ready():
	if Engine.editor_hint:
		return
	
	set_visibility(true)
	prop_disk.visible = false
	
	ray.add_exception(get_parent())
	max_ray_length = ray.cast_to.length()
	
	theta_tip = deg2rad(theta_tip)


func _process(delta):
	if Engine.editor_hint:
		return
	
	if abs(rpm) > 500:
		if !use_blur:
			use_blur = true
			prop_disk.visible = true
			set_visibility(false)
	else:
		if use_blur:
			use_blur = false
			prop_disk.visible = false
			set_visibility(true)


func set_clockwise(cw : bool):
	clockwise = cw
	set_visibility(true)


func set_visibility(show_prop : bool):
	if show_prop:
		cw.visible = clockwise
		ccw.visible = !clockwise
	else:
		cw.visible = false
		ccw.visible = false


func set_color(col : Color):
	if !is_inside_tree():
		yield(self, "ready")
	color = col
	cw.mesh.surface_get_material(0).set_shader_param("propeller_color", color)
	ccw.mesh.surface_get_material(0).set_shader_param("propeller_color", color)
	prop_disk.mesh.surface_get_material(0).set_shader_param("propeller_color", color)


func set_prop_disk_alpha(alpha : float):
	if !is_inside_tree():
		yield(self, "ready")
	prop_disk_alpha = alpha
	prop_disk.mesh.surface_get_material(0).set_shader_param("alpha_boost", prop_disk_alpha)


func set_prop_disk_emission(emission : float):
	if !is_inside_tree():
		yield(self, "ready")
	prop_disk_emission = emission
	prop_disk.mesh.surface_get_material(0).set_shader_param("emission_power", prop_disk_emission)


func set_prop_disk_falloff(falloff : float):
	if !is_inside_tree():
		yield(self, "ready")
	prop_disk_falloff = falloff
	prop_disk.mesh.surface_get_material(0).set_shader_param("emission_falloff", prop_disk_falloff)


func set_velocity(vel : Vector3):
	velocity = vel


func update_forces():
	# Forces computed according to paper from ETH Zurich: Rajan Gill and Raffaello D'Andrea
	# Computationally Efficient Force and Moment Models for Propellers in UAV Forward Flight Applications
	var rho = 1.225
	w = rpm * PI / 30.0
	var v = -velocity
	var v_len = v.length()
	var beta = acos(-v.normalized().dot(Vector3.UP))
	var lambda_c = 0.0
	var mu = 0.0
	if w != 0.0:
		lambda_c = v_len * cos(beta) / (w * radius)
		mu = v_len * sin(beta) / (w * radius)
	var sigma = num_blades * c_tip / (PI * radius)
	
	# Induced inflow
	var a1 = -4 * lambda_c + cla * sigma * (disk_delta - 1)
	var a2 = 16 * lambda_c * lambda_c + 8 * cla * (disk_delta - 1) * lambda_c * sigma
	var a3 = (disk_delta - 1) / disk_delta * sigma
	var a4 = -8 * cl0 * disk_delta * (1 + disk_delta)
	var a5 = cla * (disk_delta - 1) * disk_delta * sigma
	var a6 = 8 * (2 * disk_delta + mu * mu * theta_tip)
	var a7 = 8 * cl0 * mu * mu * sigma * log(disk_delta)
	var lambda_i = (a1 + sqrt(a2 + a3 * (a4 + cla * (a5 - a6)) - a7)) / 8.0
	
	var lambda = lambda_c + lambda_i
	
	# Thrust
	a1 = sigma / (2 * disk_delta)
	a2 = cl0 * disk_delta * (1 + disk_delta)
	a3 = 2 * cla * disk_delta * (lambda - theta_tip)
	a4 = cla * mu * mu * theta_tip
	a5 = cl0 * disk_delta * mu * mu * log(disk_delta)
	var cft = a1 * ((1 - disk_delta) * (a2 - a3 + a4) - a5)
	var thrust = 0.5 * rho * PI * radius * radius * w * w * radius * radius * cft
	
	# Drag
	a1 = mu * sigma / (2 * disk_delta)
	a2 = 2 * cd0 * disk_delta
	a3 = (cla - 2 * cda) * lambda
	a4 = 2 * cda * theta_tip
	a5 = cl0 * disk_delta * lambda * log(disk_delta)
	var cfh = a1 * ((1 - disk_delta) * (a2 + theta_tip * (a3 + a4)) - a5)
	var drag = 0.5 * rho * PI * radius * radius * w * w * radius * radius * cfh
	
	# Torque
	a1 = (1 - disk_delta) * sigma / 6.0
	a2 = 2 * cd0 * (1 + disk_delta + disk_delta * disk_delta)
	a3 = 3 * cl0 * (disk_delta + 1) * lambda
	a4 = 6 * (cda * (lambda - theta_tip) - cla * lambda) * (lambda - theta_tip)
	a5 = (3 * mu * mu * (cd0 * disk_delta + cda * theta_tip * theta_tip)) / disk_delta
	var cmq = a1 * (a2 + a3 + a4 + a5)
	var torque = 0.5 * rho * PI * radius * radius * w * w * radius * radius * radius * cmq
	
	# Rolling moment
	a1 = (1 - disk_delta) * sigma * mu / 2.0
	a2 = cl0 * (disk_delta + 1)
	a3 = cla * (lambda - 2 * theta_tip)
	var cmr = a1 * (a2 - a3)
	var roll = 0.5 * rho * PI * radius * radius * w * w * radius * radius * radius * cmr
	
	# Pitching moment
	a1 = c_tip / (2 * disk_delta * radius) * sigma * mu
	a2 = cma * (disk_delta - 1) * (lambda - 2 * theta_tip)
	a3 = 2 * cm0 * disk_delta * log(disk_delta)
	var cmp = a1 * (a2 - a3)
	var pitch = 0.5 * rho * PI * radius * radius * w * w * radius * radius * radius * cmp
	
	# Vector form
	var direction = 1
	if clockwise:
		direction = -1
	var drag_direction = Vector3(v.x, 0.0, v.z).normalized()
	if debug > 0:
		debug += 1
		if debug >= 10:
			debug = 1
			if name == "Propeller1":
				print("beta: %5.3f, lamb_c: %5.3f, mu: %5.3f, lamb_i: %5.3f" % [beta, lambda_c, mu, lambda_i])
				print("T: %5.3f, D: %5.3f, Q: %5.3f, R: %5.3f, P: %5.3f" % [thrust, drag, torque, roll, pitch])
	thrust *= Vector3.UP
	drag *= drag_direction
	torque *= Vector3.UP * direction
	roll *= drag_direction * direction
	pitch *= Vector3.UP.cross(drag_direction)
	
	forces = [thrust, drag, torque, roll, pitch]


func get_forces():
	return forces


func get_ground_effect():
	var ground_effect = 0.0
	if ray.is_colliding():
		ray_length = -global_transform.xform_inv(ray.get_collision_point()).y
		ground_effect = 1 / (1 + pow(ray_length / max_ray_length, 2)) - 0.5
	else:
		ray_length = max_ray_length
#	print("ray: %8.3f gnd: %8.3f" % [ray_length, ground_effect])
	return ground_effect
