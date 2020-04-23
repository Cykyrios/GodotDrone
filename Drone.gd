extends RigidBody

class_name Drone

var motors = []
onready var flight_controller = $FlightController

var control_profile = ControlProfile.new()
export (float, 1.0, 1800.0) var rate_pitch = 667.0
export (float, 1.0, 1800.0) var rate_roll = 667.0
export (float, 1.0, 1800.0) var rate_yaw = 667.0
export (float, 0.0, 1.0) var expo_pitch = 0.2
export (float, 0.0, 1.0) var expo_roll = 0.2
export (float, 0.0, 1.0) var expo_yaw = 0.2

var drone_transform = Transform.IDENTITY
var drone_pos = Vector3.ZERO
var drone_basis = Basis.IDENTITY

export (Vector3) var projected_area = Vector3(0.1, 0.1, 0.1)
export (Vector3) var cd = Vector3(0.3, 1.3, 0.3)

onready var debug_geom = get_tree().root.get_node("Level/DebugGeometry")
var b_debug = false


func _ready():
	motors = [$Motor1, $Motor2, $Motor3, $Motor4]
	flight_controller.set_motors(motors)
#	var prop = motors[0].propeller
#	var hover_rpm = sqrt(mass / 4 * 9.81 * 1000 / prop.LIFT_RATIO / pow(PI / 30.0, 2) / pow(prop.radius, 2))
#	flight_controller.set_hover_rpm(hover_rpm)
	flight_controller.set_hover_thrust(mass / 4 * 9.81)
	
	control_profile.set_rates(rate_pitch, rate_roll, rate_yaw)
	control_profile.set_expo(expo_pitch, expo_roll, expo_yaw)
	flight_controller.set_control_profile(control_profile)


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
	drone_transform = global_transform
	drone_pos = drone_transform.origin
	drone_basis = drone_transform.basis


func _integrate_forces(state):
	var steps = 10
	if !flight_controller.armed:
		steps = 1
	var dt = state.step / (steps as float)
	
	var xform = drone_transform
	var pos = drone_pos
	var basis = drone_basis
	var lin_vel = state.linear_velocity
	var ang_vel = state.angular_velocity
	
	for i in range(steps):
		flight_controller.integrate_loop(dt, pos, basis)
		
		var vec_force = Vector3()
		var vec_torque = Vector3()
		
		for motor in motors:
			motor.update_thrust(dt)
			var prop = motor.propeller
			var prop_xform = motor.transform * prop.transform
			var prop_force = xform.basis.xform(prop_xform.basis.y) * prop.get_thrust()
			vec_force += prop_force
			vec_torque += motor.get_torque() * basis.y
			var prop_pos = prop.global_transform.origin - global_transform.origin
			vec_torque -= prop_force.cross(xform.basis.xform(prop_xform.origin))

		var drag = get_drag(lin_vel, ang_vel, basis)
		vec_force += drag[0]
		vec_torque += drag[1]
		
		# Integrate forces and velocities
		var a = vec_force * state.inverse_mass + state.total_gravity
		lin_vel += a * dt
		pos += lin_vel * dt
		
		var ang_a = vec_torque * state.inverse_inertia
		ang_vel += ang_a * dt
		var delta_ang_vel = ang_vel * dt
		if delta_ang_vel != Vector3.ZERO:
			basis = basis.rotated(delta_ang_vel.normalized(), delta_ang_vel.length())
		
		xform = Transform(basis, pos)
	
	state.linear_velocity = lin_vel
	state.angular_velocity = ang_vel


func _on_reset():
	global_transform = Transform(Basis(), Vector3(0, 0.2, 0))
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	flight_controller.reset()


func get_drag(lin_vel : Vector3, ang_vel, orientation : Basis):
	var drag = [Vector3(), Vector3()]
	var local_vel = orientation.xform_inv(lin_vel)
	var local_ang = orientation.xform_inv(ang_vel)
	drag[0] = orientation.xform(-local_vel.length_squared() * local_vel.normalized() * projected_area * cd / 2.0 * 1.225)
	drag[1] = orientation.xform(-local_ang.length_squared() * local_ang.normalized() * projected_area * cd / 200.0 * 1.225)
	
	return drag


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
