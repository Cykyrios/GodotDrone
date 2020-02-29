extends RigidBody

class_name Drone

var motors = []
onready var flight_controller = $FlightController

onready var debug_geom = get_tree().root.get_node("Level/DebugGeometry")
var b_debug = false


func _ready():
	motors = [$Motor1, $Motor2, $Motor3, $Motor4]
	flight_controller.set_motors(motors)
#	var prop = motors[0].propeller
#	var hover_rpm = sqrt(mass / 4 * 9.81 * 1000 / prop.LIFT_RATIO / pow(PI / 30.0, 2) / pow(prop.radius, 2))
#	flight_controller.set_hover_rpm(hover_rpm)
	flight_controller.set_hover_thrust(mass / 4 * 9.81)


func _process(delta):
	if b_debug:
		for motor in motors:
			var prop = motor.propeller
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
	for motor in motors:
		var prop = motor.propeller
		var vec_torque = motor.get_torque() * global_transform.basis.y
		var vec_force = prop.global_transform.basis.y * prop.get_thrust()
		var vec_pos = prop.global_transform.origin - global_transform.origin
		add_torque(vec_torque)
		add_force(vec_force, vec_pos)
	
	add_drag()


func _on_reset():
	global_transform = Transform(Basis(), Vector3(0, 0.2, 0))
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	flight_controller.reset()


func add_drag():
	var drag = -linear_velocity.length_squared() * linear_velocity.normalized() / 20.0
	add_central_force(drag)
	
	var ang_drag = -angular_velocity.length_squared() * angular_velocity.normalized() / 20.0
	add_torque(ang_drag)


func _on_flight_mode_changed(mode):
	var led = $LEDMode
	led.set_blink(0)
	if mode == FlightController.FlightMode.RATE:
		led.change_color(Color(1, 0, 0))
	elif mode == FlightController.FlightMode.LEVEL:
		led.change_color(Color(0.2, 0.2, 1))
	elif mode == FlightController.FlightMode.SPEED:
		led.change_color(Color(1, 1, 0))
	elif mode == FlightController.FlightMode.TRACK:
		led.change_color(Color(0, 1, 0))
	elif mode == FlightController.FlightMode.AUTO:
		led.change_color(Color(1, 0, 0))
		led.set_blink(0.25)
