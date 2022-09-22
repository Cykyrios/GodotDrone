@tool
class_name Propeller
extends Node3D


@onready var cw := $CW
@onready var ccw := $CCW
@onready var prop_disk := $PropBlurDisk

@onready var ray := $RayCast3D as RayCast3D
var max_ray_length := 0.0

@export_range (0.5, 15) var diameter := 5.0
@export_range (0.5, 15) var pitch := 5.0
@export_range (2, 6) var num_blades := 2
@export_range (0.0, 0.1) var c_tip := 0.01
@export_range (0.0, 10.0) var cl0 := 0.1
@export_range (0.0, 10.0) var cla := 0.1
@export_range (0.0, 10.0) var cd0 := 0.1
@export_range (0.0, 10.0) var cda := 0.1
@export_range (0.0, 10.0) var cm0 := 0.1
@export_range (0.0, 10.0) var cma := 0.1
@export_range (0.0, 10.0) var disk_delta := 0.2

var clockwise := false :
	set(is_cw):
		clockwise = is_cw
		set_visibility(true)
var rpm := 0.0
var use_blur := false
@export var color := Color(1.0, 1.0, 1.0, 1.0) :
	set(col):
		if !is_inside_tree():
			await self.ready
		color = col
		cw.mesh.surface_get_material(0).set_shader_parameter("propeller_color", color)
		ccw.mesh.surface_get_material(0).set_shader_parameter("propeller_color", color)
		prop_disk.mesh.surface_get_material(0).set_shader_parameter("propeller_color", color)
@export_range (1, 3) var prop_disk_alpha := 1.0 :
	set(alpha):
		if !is_inside_tree():
			await self.ready
		prop_disk_alpha = alpha
		prop_disk.mesh.surface_get_material(0).set_shader_parameter("alpha_boost", prop_disk_alpha)
@export_range (0, 2) var prop_disk_emission := 0.0 :
	set(emission):
		if !is_inside_tree():
			await self.ready
		prop_disk_emission = emission
		prop_disk.mesh.surface_get_material(0).set_shader_parameter("emission_power", prop_disk_emission)
@export_range (1, 20) var prop_disk_falloff := 10 :
	set(falloff):
		if !is_inside_tree():
			await self.ready
		prop_disk_falloff = falloff
		prop_disk.mesh.surface_get_material(0).set_shader_parameter("emission_falloff", prop_disk_falloff)

var velocity := Vector3.ZERO
var forces := [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]

var radius := diameter * 0.0254 / 2.0
var theta_tip := 1.25 * pitch / (PI * diameter)
var w := 0.0

# Ground effect parameters
var gnd_radius := 0.0
var gnd_d := 0.0
var gnd_b := 0.0
var gnd_kb := 0.0

var debug := 0


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	set_visibility(true)
	prop_disk.visible = false

	var parent: Node3D = get_parent()
	while not parent is Drone:
		if parent is CollisionObject3D:
			ray.add_exception(parent)
		parent = parent.get_parent()
		if parent is Drone:
			ray.add_exception(parent)
		elif not parent:
			break
	max_ray_length = min(diameter * 0.0254 * 2, ray.target_position.length())
	ray.target_position = ray.target_position.normalized() * max_ray_length
	ray.enabled = true

	theta_tip = deg_to_rad(theta_tip)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
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


func set_visibility(show_prop: bool) -> void:
	if show_prop:
		cw.visible = clockwise
		ccw.visible = !clockwise
	else:
		cw.visible = false
		ccw.visible = false


func update_forces() -> void:
	# Forces computed according to paper from ETH Zurich: Rajan Gill and Raffaello D'Andrea
	# Computationally Efficient Force and Moment Models for Propellers in UAV Forward Flight Applications
	var rho := 1.225
	w = rpm * PI / 30.0
	var v := -velocity
	var v_len := v.length()
	var beta := acos(-v.normalized().dot(Vector3.UP))
	var lambda_c := 0.0
	var mu := 0.0
	if w != 0.0:
		lambda_c = v_len * cos(beta) / (w * radius)
		mu = v_len * sin(beta) / (w * radius)
	var sigma := num_blades * c_tip / (PI * radius)

	# Induced inflow
	var a1 := -4 * lambda_c + cla * sigma * (disk_delta - 1)
	var a2 := 16 * lambda_c * lambda_c + 8 * cla * (disk_delta - 1) * lambda_c * sigma
	var a3 := (disk_delta - 1) / disk_delta * sigma
	var a4 := -8 * cl0 * disk_delta * (1 + disk_delta)
	var a5 := cla * (disk_delta - 1) * disk_delta * sigma
	var a6 := 8 * (2 * disk_delta + mu * mu * theta_tip)
	var a7 := 8 * cl0 * mu * mu * sigma * log(disk_delta)
	var lambda_i := (a1 + sqrt(a2 + a3 * (a4 + cla * (a5 - a6)) - a7)) / 8.0

	var lambda := lambda_c + lambda_i

	# Thrust
	a1 = sigma / (2 * disk_delta)
	a2 = cl0 * disk_delta * (1 + disk_delta)
	a3 = 2 * cla * disk_delta * (lambda - theta_tip)
	a4 = cla * mu * mu * theta_tip
	a5 = cl0 * disk_delta * mu * mu * log(disk_delta)
	var cft := a1 * ((1 - disk_delta) * (a2 - a3 + a4) - a5)
	var thrust := 0.5 * rho * PI * radius * radius * w * w * radius * radius * cft

	# Drag
	a1 = mu * sigma / (2 * disk_delta)
	a2 = 2 * cd0 * disk_delta
	a3 = (cla - 2 * cda) * lambda
	a4 = 2 * cda * theta_tip
	a5 = cl0 * disk_delta * lambda * log(disk_delta)
	var cfh := a1 * ((1 - disk_delta) * (a2 + theta_tip * (a3 + a4)) - a5)
	var drag := 0.5 * rho * PI * radius * radius * w * w * radius * radius * cfh

	# Torque
	a1 = (1 - disk_delta) * sigma / 6.0
	a2 = 2 * cd0 * (1 + disk_delta + disk_delta * disk_delta)
	a3 = 3 * cl0 * (disk_delta + 1) * lambda
	a4 = 6 * (cda * (lambda - theta_tip) - cla * lambda) * (lambda - theta_tip)
	a5 = (3 * mu * mu * (cd0 * disk_delta + cda * theta_tip * theta_tip)) / disk_delta
	var cmq := a1 * (a2 + a3 + a4 + a5)
	var torque := 0.5 * rho * PI * radius * radius * w * w * radius * radius * radius * cmq

	# Rolling moment
	a1 = (1 - disk_delta) * sigma * mu / 2.0
	a2 = cl0 * (disk_delta + 1)
	a3 = cla * (lambda - 2 * theta_tip)
	var cmr := a1 * (a2 - a3)
	var roll_moment := 0.5 * rho * PI * radius * radius * w * w * radius * radius * radius * cmr

	# Pitching moment
	a1 = c_tip / (2 * disk_delta * radius) * sigma * mu
	a2 = cma * (disk_delta - 1) * (lambda - 2 * theta_tip)
	a3 = 2 * cm0 * disk_delta * log(disk_delta)
	var cmp := a1 * (a2 - a3)
	var pitch_moment := 0.5 * rho * PI * radius * radius * w * w * radius * radius * radius * cmp

	# Vector form
	var direction := 1
	if clockwise:
		direction = -1
	var drag_direction := Vector3(v.x, 0.0, v.z).normalized()
	if debug > 0:
		debug += 1
		if debug >= 10:
			debug = 1
			if name == "Propeller1":
				print("beta: %5.3f, lamb_c: %5.3f, mu: %5.3f, lamb_i: %5.3f"
						% [beta, lambda_c, mu, lambda_i])
				print("T: %5.3f, D: %5.3f, Q: %5.3f, R: %5.3f, P: %5.3f"
						% [thrust, drag, torque, roll_moment, pitch_moment])
	var thrust_vec := thrust * Vector3.UP
	var drag_vec := drag * drag_direction
	var torque_vec := torque * Vector3.UP * direction
	var roll_moment_vec := roll_moment * drag_direction * direction
	var pitch_moment_vec := pitch_moment * Vector3.UP.cross(drag_direction)

	thrust_vec = thrust_vec * get_ground_effect()

	forces = [thrust_vec, drag_vec, torque_vec, roll_moment_vec, pitch_moment_vec]


func set_ground_effect_parameters(rad: float, d: float, b: float, kb: float) ->  void:
	gnd_radius = rad
	gnd_d = d
	gnd_b = b
	gnd_kb = kb


func get_ground_effect() -> float:
	# Ground effect calculated according to paper from Hindawi
	# Characterization of the Aerodynamic Ground Effect and Its Influence in Multirotor Control
	var ground_effect := 1.0
	var ray_length := max_ray_length
	if ray.is_colliding():
#		ray_length = minf((ray.get_collision_point() - global_transform.origin).length(), max_ray_length)
		ray_length = minf(absf((ray.get_collision_point() * global_transform).y), max_ray_length)
		var b_square := gnd_b * gnd_b
		var d_square := gnd_d * gnd_d
		var r_square := gnd_radius * gnd_radius
		var z_square := ray_length * ray_length
		var b1 := gnd_radius / (4 * ray_length)
		var a1 := b1 * b1
		var b2 := d_square + 4 * z_square
		var a2 := r_square * ray_length / sqrt(b2 * b2 * b2)
		var b3 := 2 * d_square + 4 * z_square
		var a3 := 0.5 * r_square * ray_length / sqrt(b3 * b3 * b3)
		var b4 := b_square + 4 * z_square
		var a4 := 2 * r_square * ray_length / sqrt(b4 * b4 * b4) * gnd_kb
		ground_effect = clamp(1.0 / (1 - a1 - a2 - a3 - a4), 1, 2)
		if ground_effect < 1.01 and ray_length < 2 * gnd_radius:
			ground_effect = 2
	return ground_effect
