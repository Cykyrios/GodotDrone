class_name Drone
extends RigidBody3D


signal respawned
signal transform_updated(transform)


var motors := []
@onready var flight_controller := $FlightController
var hud := preload("res://HUD/HUD.tscn").instantiate()

var control_profile := ControlProfile.new()
@export_range (1.0, 1800.0) var rate_pitch := 667.0
@export_range (1.0, 1800.0) var rate_roll := 667.0
@export_range (1.0, 1800.0) var rate_yaw := 667.0
@export_range (0.0, 1.0) var expo_pitch := 0.2
@export_range (0.0, 1.0) var expo_roll := 0.2
@export_range (0.0, 1.0) var expo_yaw := 0.2

var drone_transform := Transform3D.IDENTITY
var drone_pos := Vector3.ZERO
var drone_basis := Basis.IDENTITY

@export var projected_area := Vector3(0.1, 0.1, 0.1)
@export var cd := Vector3(0.3, 1.3, 0.3)

var ray : RayCast3D

#@onready var debug_geom := get_tree().root.get_node_or_null("Level/DebugGeometry")
var b_debug := false


func _ready() -> void:
	for shape in $Frame.collision_shapes:
		$Frame.remove_child(shape)
		add_child(shape)
	motors = [$Motor1, $Motor2, $Motor3, $Motor4]
	flight_controller.set_motors(motors)
#	var prop = motors[0].propeller
#	var hover_rpm = sqrt(mass / 4 * 9.81 * 1000 / prop.LIFT_RATIO / pow(PI / 30.0, 2) / pow(prop.radius, 2))
#	flight_controller.set_hover_rpm(hover_rpm)
	flight_controller.set_hover_thrust(mass / 4 * 9.81)

	# Ground effect parameters
	var rad: float = motors[0].propeller.diameter * 0.0254 * 0.5
	var d: float = min((motors[0].transform.origin - motors[1].transform.origin).length(),
			(motors[0].transform.origin - motors[3].transform.origin).length())
	var b: float = (motors[0].transform.origin - motors[2].transform.origin).length()
	for motor in motors:
		motor.propeller.set_ground_effect_parameters(rad, d, b, 1)

	add_child(hud)
	var _discard = flight_controller.armed.connect(hud.status._on_armed)
	_discard = flight_controller.disarmed.connect(hud.status._on_disarmed)
	_discard = flight_controller.flight_mode_changed.connect(hud.status._on_mode_changed)
	_discard = flight_controller.arm_failed.connect(hud.status._on_arm_failed)

	add_child(control_profile)
	control_profile.set_rates(rate_pitch, rate_roll, rate_yaw)
	control_profile.set_expos(expo_pitch, expo_roll, expo_yaw)
	flight_controller.set_control_profile(control_profile)

	QuadSettings.load_quad_settings()
	_discard = QuadSettings.settings_updated.connect(_on_quad_settings_updated)
	_on_quad_settings_updated()

	GameSettings.load_hud_config()
	_discard = GameSettings.hud_config_updated.connect(_on_hud_config_updated)
	_on_hud_config_updated()

	# Add anti-checkpoint ghosting raycast
	ray = RayCast3D.new()
	ray.collide_with_areas = true
	ray.collide_with_bodies = false
	for motor in motors:
		for child in motor.get_children():
			if child is Area3D:
				ray.add_exception(child)
			else:
				for great_child in child.get_children():
					if great_child is Area3D:
						ray.add_exception(great_child)
	add_child(ray)
	ray.enabled = true



func _process(delta: float) -> void:
	update_hud_data(delta)

#	if b_debug and debug_geom:
	if b_debug:
		for motor in motors:
			var prop = motor.propeller
			var vec_force: Vector3 = prop.global_transform.basis.y * prop.get_thrust()
			var vec_pos: Vector3 = prop.global_transform.origin - global_transform.origin
#			debug_geom.draw_debug_arrow(delta, global_transform.origin + vec_pos, vec_force,
#					vec_force.length() / 50, Color(5, 1, 0))

		var global_xform := global_transform
		var global_basis := global_xform.basis
#		debug_geom.draw_debug_grid(0.02, global_xform * Vector3(0, 0, 0), 1.5, 1.5, 1, 1,
#				Vector3.UP, global_basis * Vector3.RIGHT)
#		debug_geom.draw_debug_arrow(0.02, global_xform * Vector3.UP,
#				linear_velocity, linear_velocity.length() / 10)
#		debug_geom.draw_debug_arrow(0.02, global_xform * Vector3.UP,
#				Vector3.RIGHT, linear_velocity.x / 10, Color(10, 0, 0))
#		debug_geom.draw_debug_arrow(0.02, global_xform * Vector3.UP,
#				Vector3.UP, linear_velocity.y / 10, Color(0, 10, 0))
#		debug_geom.draw_debug_arrow(0.02, global_xform * Vector3.UP,
#				Vector3.BACK, linear_velocity.z / 10, Color(0, 0, 10))

#		debug_geom.draw_debug_arrow(0.02, global_xform * Vector3(0.2, 0, 0.5),
#				global_basis * Vector3.RIGHT, (linear_velocity * global_basis).x / 10,
#				Color(10, 0, 0))
#		debug_geom.draw_debug_arrow(0.02, global_xform * Vector3(-0.2, 0, 0.5),
#				global_basis * Vector3.UP, linear_velocity.y / 10,
#				Color(0, 10, 0))
#		debug_geom.draw_debug_arrow(0.02, global_xform * Vector3(0.2, 0, 0.5),
#				global_basis * Vector3.DOWN, (linear_velocity * global_basis).z / 10,
#				Color(0, 0, 10))


func _physics_process(_delta: float) -> void:
	drone_transform = global_transform
	drone_pos = drone_transform.origin
	drone_basis = drone_transform.basis

	var replay_transform := "%s, %s, %s, %s" % [drone_basis.x, drone_basis.y, drone_basis.z, drone_pos]
	replay_transform = replay_transform.replace("(", "").replace(")", "").replace(" ", "")
	transform_updated.emit(replay_transform)

	# Cast a ray 1 meter in the direction of the drone's velocity vector
	# This is used as a backup check for checkpoints at high speeds
	var cast_vector := linear_velocity * drone_transform.basis
	if cast_vector.length_squared() > 1:
		cast_vector = cast_vector.normalized()
	ray.target_position = cast_vector
	ray.force_raycast_update()
	if ray.is_colliding():
		var collider := ray.get_collider()
		if collider is Area3D and collider.has_method("_on_drone_raycast_hit"):
			collider.call("_on_drone_raycast_hit", self)

#	if b_debug and debug_geom:
#		var drag: Vector3 = get_drag(linear_velocity, angular_velocity, drone_basis)[0]
#		debug_geom.draw_debug_arrow(0.01, drone_pos, drag.normalized(), drag.length() / 10)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var steps := 10
	if !flight_controller.state_armed:
		steps = 1
	var dt := state.step / (steps as float)

	var xform := drone_transform.orthonormalized()
	var pos = xform.origin
	var bas := xform.basis
	var lin_vel := state.linear_velocity
	var ang_vel := state.angular_velocity

	for i in range(steps):
		flight_controller.integrate_loop(dt, pos, bas)

		var vec_force := Vector3.ZERO
		var vec_torque := Vector3.ZERO

		for motor in motors:
			motor.update_thrust(dt)
			var prop = motor.propeller
			var prop_pos: Vector3 = prop.global_transform.origin - global_transform.origin
			var prop_xform: Transform3D = motor.transform * prop.transform
			var prop_local_pos: Vector3 = prop_pos * prop_xform
			prop.velocity = lin_vel * bas + (ang_vel * bas).cross(prop_local_pos)
			prop.update_forces()
			var prop_forces: Array = prop.forces
			var prop_thrust: Vector3 = bas * prop_forces[0]
			if motor.rpm < 0:
				prop_thrust = -prop_thrust / 2
			var prop_drag: Vector3 = bas * prop_forces[1]
#			if b_debug and debug_geom and i == 0 and prop.name == "Propeller1":
#				print("V: %5.2f, T: %5.2f, D: %5.2f" % [prop.velocity.y, prop_forces[0].length(),
#						prop_forces[1].length()])
#				# Draw debug arrows relative to FPV camera
#				debug_geom.draw_debug_arrow(0.016, xform * Vector3(0, 1, -2),
#						prop_thrust.normalized(), prop_thrust.length() / 10.0, Color(1, 0, 0))
#				debug_geom.draw_debug_arrow(0.016, xform * Vector3(0, 1, -2),
#						prop_drag.normalized(), prop_drag.length() / 5.0, Color(0, 1, 0))
			vec_force += prop_thrust + prop_drag
			vec_torque += motor.torque * bas.y
			vec_torque -= prop_thrust.cross(bas * prop_xform.origin)

		var drag := get_drag(lin_vel, ang_vel, bas)
		vec_force += drag[0]
		vec_torque += drag[1]

		# Integrate forces and velocities
		var a := vec_force * state.inverse_mass + Vector3(0, -9.81, 0)
		lin_vel += a * dt
		pos += lin_vel * dt

		var ang_a := vec_torque * state.inverse_inertia
		ang_vel += ang_a * dt
		var delta_ang_vel := ang_vel * dt
		if delta_ang_vel != Vector3.ZERO:
			bas = bas.rotated(delta_ang_vel.normalized(), delta_ang_vel.length())

		xform = Transform3D(bas, pos)

	state.linear_velocity = lin_vel
	state.angular_velocity = ang_vel


func update_hud_data(delta: float) -> void:
	var angles: Vector3 = flight_controller.angles
	var velocity: Vector3 = flight_controller.lin_vel
	var pos: Vector3 = flight_controller.pos
	var input: Array = flight_controller.input
	var left_stick := Vector2(input[1], -2 * (input[0] - 0.5))
	var right_stick := Vector2(input[2], input[3])
	var mot: Array = flight_controller.motors
	var rpm := [mot[0].rpm, mot[1].rpm, mot[2].rpm, mot[3].rpm]
	hud.update_data(delta, pos, angles, velocity, left_stick, right_stick, rpm)


func reset() -> void:
	_on_reset()


func _on_reset() -> void:
	var respawn_point: Node3D = get_tree().root.get_children()[-1].get_node("Respawn")
	var respawn_transform := respawn_point.global_transform.translated(Vector3(0, 0.1, 0))

	if Global.game_mode == Global.GameMode.RACE and Global.active_track:
		var launch_area: LaunchArea = Global.active_track.get_random_launch_area()
		var launch_transform: Transform3D = launch_area.global_transform
		var offset: float = -motors[0].transform.origin.z + 0.02
		respawn_transform = launch_transform.translated_local(Vector3(0, 0.1, offset))

	await get_tree().physics_frame
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = respawn_transform
	flight_controller.reset()

	respawned.emit()


func get_drag(lin_vel: Vector3, ang_vel: Vector3, orientation: Basis) -> Array:
	var drag := [Vector3.ZERO, Vector3.ZERO]
	var local_vel := lin_vel * orientation
	var local_ang := ang_vel * orientation
	var local_drag := [Vector3.ZERO, Vector3.ZERO]
	local_drag[0] = -local_vel.length() * local_vel * projected_area * cd / 2.0 * 1.225
	local_drag[1] = -local_ang.length() * local_ang * projected_area * cd / 200.0 * 1.225
	drag[0] = orientation * local_drag[0]
	drag[1] = orientation * local_drag[1]

	return drag


func _on_flight_mode_changed(flight_mode: int) -> void:
	var led := $LEDMode
	led.blink_pattern = []
	if flight_mode == FlightController.FlightMode.RATE:
		led.change_color(Color(1, 0, 0))
	elif flight_mode == FlightController.FlightMode.LEVEL:
		led.change_color(Color(0.2, 0.2, 1))
	elif flight_mode == FlightController.FlightMode.SPEED:
		led.change_color(Color(1, 1, 0))
	elif flight_mode == FlightController.FlightMode.TRACK:
		led.change_color(Color(0, 1, 0))
	elif flight_mode == FlightController.FlightMode.AUTO:
		led.change_color(Color(1, 0, 0))
		led.blink_pattern = [Vector2(0.25, 0.25)]
	elif flight_mode == FlightController.FlightMode.TURTLE:
		led.change_color(Color(1, 0, 0))
		led.blink_pattern = [Vector2(0.1, 0.1), Vector2(0.1, 0.7)]
	elif flight_mode == FlightController.FlightMode.LAUNCH:
		led.change_color(Color(1, 0, 0))
		led.blink_pattern = [Vector2(0.15, 0.15), Vector2(0.55, 0.15)]

	hud.update_flight_mode(flight_mode)


func _on_quad_settings_updated() -> void:
	mass = QuadSettings.dry_weight + QuadSettings.battery_weight
	$FPVCamera.transform.basis = Basis.IDENTITY.rotated(Vector3.RIGHT, deg_to_rad(QuadSettings.angle))
	control_profile.set_rates(QuadSettings.rate_pitch, QuadSettings.rate_roll, QuadSettings.rate_yaw)
	control_profile.set_expos(QuadSettings.expo_pitch, QuadSettings.expo_roll, QuadSettings.expo_yaw)


func _on_hud_config_updated() -> void:
	hud.hud_timer = 1.0 / GameSettings.hud_config["fps"]
	hud.show_component(HUD.Component.CROSSHAIR, GameSettings.hud_config["crosshair"])
	hud.show_component(HUD.Component.HORIZON, GameSettings.hud_config["horizon"])
	hud.show_component(HUD.Component.LADDER, GameSettings.hud_config["ladder"])
	hud.show_component(HUD.Component.SPEED, GameSettings.hud_config["speed"])
	hud.show_component(HUD.Component.ALTITUDE, GameSettings.hud_config["altitude"])
	hud.show_component(HUD.Component.HEADING, GameSettings.hud_config["heading"])
	hud.show_component(HUD.Component.STICKS, GameSettings.hud_config["sticks"])
	hud.show_component(HUD.Component.RPM, GameSettings.hud_config["rpm"])
