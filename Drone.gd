extends RigidBody

class_name Drone

var props
onready var flight_controller = $FlightController

var control_input = 0.0

var climb = 0.0
const CLIMB_RPM = 1000.0
const PROP_LIFT = 0.025

var target_altitude = 0.0

onready var debug_geom = get_tree().root.get_node("Level/DebugGeometry")


func _ready():
	props = [$Propeller1, $Propeller2, $Propeller3, $Propeller4]
	flight_controller.set_props(props)
	flight_controller.set_hover_thrust(mass / 4 * 9.8)


func _process(delta):
	for prop in props:
		var vec_force = prop.global_transform.basis.y * prop.get_thrust()
		var vec_pos = prop.global_transform.origin - global_transform.origin
		debug_geom.draw_debug_arrow(delta, global_transform.origin + vec_pos, vec_force, vec_force.length() / 50,
				Color(5, 1, 0))
	
	debug_geom.draw_debug_grid(0.02, global_transform.xform(Vector3(0, 0, 0)), 1.5, 1.5, 1, 1,
			Vector3.UP, global_transform.basis.xform(Vector3.RIGHT))
	debug_geom.draw_debug_arrow(0.02, global_transform.xform(Vector3.UP),
			linear_velocity, linear_velocity.length() / 10)
	debug_geom.draw_debug_arrow(0.02, global_transform.xform(Vector3.UP),
			Vector3.RIGHT, linear_velocity.x / 10, Color(10, 0, 0))
	debug_geom.draw_debug_arrow(0.02, global_transform.xform(Vector3.UP),
			Vector3.UP, linear_velocity.y / 10, Color(0, 10, 0))
	debug_geom.draw_debug_arrow(0.02, global_transform.xform(Vector3.UP),
			Vector3.BACK, linear_velocity.z / 10, Color(0, 0, 10))
	
	debug_geom.draw_debug_arrow(0.02, global_transform.xform(Vector3(0.2, 0, 0.5)),
			global_transform.basis.xform(Vector3.RIGHT), global_transform.basis.xform_inv(linear_velocity).x / 10,
			Color(10, 0, 0))
	debug_geom.draw_debug_arrow(0.02, global_transform.xform(Vector3(-0.2, 0, 0.5)),
			global_transform.basis.xform(Vector3.UP), linear_velocity.y / 10,
			Color(0, 10, 0))
	debug_geom.draw_debug_arrow(0.02, global_transform.xform(Vector3(0.2, 0, 0.5)),
			global_transform.basis.xform(Vector3.DOWN), global_transform.basis.xform_inv(linear_velocity).z / 10,
			Color(0, 0, 10))


func _physics_process(delta):
	for prop in props:
		var vec_torque = prop.get_torque() * global_transform.basis.y
		var vec_force = prop.global_transform.basis.y * prop.get_thrust()
		var vec_pos = prop.global_transform.origin - global_transform.origin
		add_torque(vec_torque)
		add_force(vec_force, vec_pos)
	
	add_drag()


func _input(event):
#	if event is InputEventMouseButton and event.is_pressed():
#		if event.button_index == BUTTON_LEFT:
#			target_altitude += 1.0
#		elif event.button_index == BUTTON_RIGHT:
#			target_altitude -= 1.0
#		print(target_altitude)
#
#	# generate control input as Vector3 for desired movement?
#	control_input = target_altitude
	
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == BUTTON_LEFT:
			apply_central_impulse(Vector3.LEFT)
	pass


func add_drag():
	var drag = -linear_velocity.length_squared() * linear_velocity.normalized() / 10.0
	add_central_force(drag)
	
	drag = -angular_velocity.length_squared() * angular_velocity.normalized() / 10.0
	add_torque(drag)
