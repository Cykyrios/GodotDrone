extends Node
class_name RadioController


signal reset_requested
signal mode_changed
signal arm_input
signal disarm_input


export (NodePath) var target_path = null
var target = null

var input := [0.0, 0.0, 0.0, 0.0]

var axis_bindings := []


func _ready() -> void:
	target = get_node(target_path)
	
	var action_list := Controls.action_list
	for controller_action in action_list:
		if controller_action.type == ControllerAction.Type.AXIS:
			axis_bindings.append(controller_action)
	
	var _discard = connect("reset_requested", target, "_on_reset")
	_discard = connect("mode_changed", target.flight_controller, "_on_cycle_flight_modes")
	_discard = connect("arm_input", target.flight_controller, "_on_arm_input")
	_discard = connect("disarm_input", target.flight_controller, "_on_disarm_input")


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion:
		var controller_action = null
		for i in range(axis_bindings.size()):
			if event.axis == axis_bindings[i].axis:
				controller_action = axis_bindings[i]
				var action: String = controller_action.action_name
				var bound_low: float = controller_action.axis_min
				var bound_high: float = controller_action.axis_max
				var axis_value: float = event.axis_value
				if !Input.is_action_pressed(action) and axis_value >= bound_low and axis_value <= bound_high:
					Input.parse_input_event(simulate_action_event(action, true))
				elif Input.is_action_pressed(action) and (axis_value < bound_low or axis_value > bound_high):
					Input.parse_input_event(simulate_action_event(action, false))
	elif Input.is_action_just_pressed("respawn"):
		emit_signal("reset_requested")
	elif event.is_action_pressed("cycle_flight_modes"):
		emit_signal("mode_changed")
	elif event.is_action_pressed("toggle_arm"):
		if target.flight_controller.armed == false:
			emit_signal("arm_input")
		else:
			emit_signal("disarm_input")
	elif event.is_action("arm"):
		if Input.is_action_just_pressed("arm"):
			emit_signal("arm_input")
		elif Input.is_action_just_released("arm"):
			emit_signal("disarm_input")
	# TODO: Add other actions
#	elif event.is_action("mode_angle"):
#		if event.is_action_pressed("mode_angle"):
#			print("Angle mode")
#	elif event.is_action("mode_horizon"):
#		if event.is_action_pressed("mode_horizon"):
#			print("Horizon mode")


func _physics_process(_delta: float) -> void:
	read_input()
	
	if target is Drone:
		target.flight_controller.input = input


func read_input() -> void:
	var power = (Input.get_action_strength("throttle_up") - Input.get_action_strength("throttle_down") + 1) / 2
	var pitch = Input.get_action_strength("pitch_up") - Input.get_action_strength("pitch_down")
	var roll = Input.get_action_strength("roll_right") - Input.get_action_strength("roll_left")
	var yaw = Input.get_action_strength("yaw_right") - Input.get_action_strength("yaw_left")
	input = [power, yaw, roll, pitch]


func simulate_action_event(action_name: String, action_pressed: bool) -> InputEventAction:
	var event = InputEventAction.new()
	event.action = action_name
	event.pressed = action_pressed
	return event
