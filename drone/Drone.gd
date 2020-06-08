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
	for shape in $Frame.collision_shapes:
		$Frame.remove_child(shape)
		add_child(shape)
	motors = [$Motor1, $Motor2, $Motor3, $Motor4]
	flight_controller.set_motors(motors)
#	var prop = motors[0].propeller
#	var hover_rpm = sqrt(mass / 4 * 9.81 * 1000 / prop.LIFT_RATIO / pow(PI / 30.0, 2) / pow(prop.radius, 2))
#	flight_controller.set_hover_rpm(hover_rpm)
	flight_controller.set_hover_thrust(mass / 4 * 9.81)
	
	add_child(control_profile)
	control_profile.set_rates(rate_pitch, rate_roll, rate_yaw)
	control_profile.set_expo(expo_pitch, expo_roll, expo_yaw)
	flight_controller.set_control_profile(control_profile)
	
	QuadSettings.connect("settings_updated", self, "_on_quad_settings_updated")
	_on_quad_settings_updated()


func _process(delta):
	if b_debug:
		for motor in motors:
			var prop = motor.propeller
			var vec_force = prop.global_transform.basis.y * prop.get_thrust()
			var vec_pos = prop.global_transform.origin - global_transform.origin
			debug_geom.draw_debug_arrow(delta, global_transform.origin + vec_pos, vec_force, vec_force.length() / 50,
					Color(5, 1, 0))
		
		var global_xform = global_transform
		var global_basis = global_xform.basis
		debug_geom.draw_debug_grid(0.02, global_xform.xform(Vector3(0, 0, 0)), 1.5, 1.5, 1, 1,
				Vector3.UP, global_basis.xform(Vector3.RIGHT))
		debug_geom.draw_debug_arrow(0.02, global_xform.xform(Vector3.UP),
				linear_velocity, linear_velocity.length() / 10)
		debug_geom.draw_debug_arrow(0.02, global_xform.xform(Vector3.UP),
				Vector3.RIGHT, linear_velocity.x / 10, Color(10, 0, 0))
		debug_geom.draw_debug_arrow(0.02, global_xform.xform(Vector3.UP),
				Vector3.UP, linear_velocity.y / 10, Color(0, 10, 0))
		debug_geom.draw_debug_arrow(0.02, global_xform.xform(Vector3.UP),
				Vector3.BACK, linear_velocity.z / 10, Color(0, 0, 10))
		
		debug_geom.draw_debug_arrow(0.02, global_xform.xform(Vector3(0.2, 0, 0.5)),
				global_basis.xform(Vector3.RIGHT), global_basis.xform_inv(linear_velocity).x / 10,
				Color(10, 0, 0))
		debug_geom.draw_debug_arrow(0.02, global_xform.xform(Vector3(-0.2, 0, 0.5)),
				global_basis.xform(Vector3.UP), linear_velocity.y / 10,
				Color(0, 10, 0))
		debug_geom.draw_debug_arrow(0.02, global_xform.xform(Vector3(0.2, 0, 0.5)),
				global_basis.xform(Vector3.DOWN), global_basis.xform_inv(linear_velocity).z / 10,
				Color(0, 0, 10))


func _physics_process(delta):
	drone_transform = global_transform
	drone_pos = drone_transform.origin
	drone_basis = drone_transform.basis
	
	if b_debug:
		var drag = get_drag(linear_velocity, angular_velocity, drone_basis)[0]
		debug_geom.draw_debug_arrow(0.01, drone_pos, drag.normalized(), drag.length() / 10)


func _integrate_forces(state):
	var steps = 10
	if !flight_controller.armed:
		steps = 1
	var dt = state.step / (steps as float)
	
	var xform = drone_transform.orthonormalized()
	var pos = xform.origin
	var basis = xform.basis
	var lin_vel = state.linear_velocity
	var ang_vel = state.angular_velocity
	
	for i in range(steps):
		flight_controller.integrate_loop(dt, pos, basis)
		
		var vec_force = Vector3()
		var vec_torque = Vector3()
		
		for motor in motors:
			motor.update_thrust(dt)
			var prop = motor.propeller
			var prop_pos = prop.global_transform.origin - global_transform.origin
			var prop_xform = motor.transform * prop.transform
			var prop_local_pos = prop_xform.xform_inv(prop_pos)
			prop.set_velocity(basis.xform_inv(lin_vel) + basis.xform_inv(ang_vel).cross(prop_local_pos))
			prop.update_forces()
			var prop_forces = prop.get_forces()
			var prop_thrust = basis.xform(prop_forces[0])
			if motor.rpm < 0:
				prop_thrust = -prop_thrust / 2
			var prop_drag = basis.xform(prop_forces[1])
			if b_debug and i == 0 and prop.name == "Propeller1":
				print("V: %5.2f, T: %5.2f, D: %5.2f" % [prop.velocity.y, prop_forces[0].length(), prop_forces[1].length()])
				# Draw debug arrows relative to FPV camera
				debug_geom.draw_debug_arrow(0.016, xform.xform(Vector3(0, 1, -2)),
						prop_thrust.normalized(), prop_thrust.length() / 10.0, Color(1, 0, 0))
				debug_geom.draw_debug_arrow(0.016, xform.xform(Vector3(0, 1, -2)),
						prop_drag.normalized(), prop_drag.length() / 5.0, Color(0, 1, 0))
			vec_force += prop_thrust + prop_drag
			vec_torque += motor.get_torque() * basis.y
			vec_torque -= prop_thrust.cross(basis.xform(prop_xform.origin))

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
	var local_drag = [Vector3(), Vector3()]
	local_drag[0] = -local_vel.length() * local_vel * projected_area * cd / 2.0 * 1.225
	local_drag[1] = -local_ang.length() * local_ang * projected_area * cd / 200.0 * 1.225
	drag[0] = orientation.xform(local_drag[0])
	drag[1] = orientation.xform(local_drag[1])
	
	return drag


func _on_flight_mode_changed(mode):
	var led = $LEDMode
	led.set_blink_pattern()
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
		led.set_blink_pattern([Vector2(0.25, 0.25)])
	elif mode == FlightController.FlightMode.TURTLE:
		led.change_color(Color(1, 0, 0))
		led.set_blink_pattern([Vector2(0.1, 0.1), Vector2(0.1, 0.7)])
	elif mode == FlightController.FlightMode.LAUNCH:
		led.change_color(Color(1, 0, 0))
		led.set_blink_pattern([Vector2(0.15, 0.15), Vector2(0.55, 0.15)])


func _on_quad_settings_updated():
	mass = QuadSettings.dry_weight + QuadSettings.battery_weight
	control_profile.set_rates(QuadSettings.rate_pitch, QuadSettings.rate_roll, QuadSettings.rate_yaw)
	control_profile.set_expo(QuadSettings.expo_pitch, QuadSettings.expo_roll, QuadSettings.expo_yaw)
