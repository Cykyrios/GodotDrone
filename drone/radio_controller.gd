extends Node
class_name RadioController


signal reset_requested
signal mode_changed
signal arm_input
signal disarm_input


@export var target_path: NodePath = ^""
var target: Drone = null

var input := FlightCommand.new()

var axis_bindings: Array[ControllerAction] = []


func _ready() -> void:
	target = get_node(target_path)

	var action_list := Controls.action_list
	for controller_action in action_list:
		if controller_action.type == ControllerAction.Type.AXIS:
			axis_bindings.append(controller_action)

	var _discard := reset_requested.connect(target._on_reset)
	_discard = mode_changed.connect(target.flight_controller._on_cycle_flight_modes)
	_discard = arm_input.connect(target.flight_controller._on_arm_input)
	_discard = disarm_input.connect(target.flight_controller._on_disarm_input)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion:
		var controller_action: ControllerAction = null
		for i in axis_bindings.size():
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
		reset_requested.emit()
	elif event.is_action_pressed("cycle_flight_modes"):
		mode_changed.emit()
	elif event.is_action_pressed("toggle_arm"):
		if target.flight_controller.state_armed == false:
			arm_input.emit()
		else:
			disarm_input.emit()
	elif event.is_action("arm"):
		if Input.is_action_just_pressed("arm"):
			arm_input.emit()
		elif Input.is_action_just_released("arm"):
			disarm_input.emit()
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
	var power := (Input.get_axis("throttle_down", "throttle_up") + 1) / 2
	var pitch := Input.get_axis("pitch_down", "pitch_up")
	var roll := Input.get_axis("roll_left", "roll_right")
	var yaw := Input.get_axis("yaw_left", "yaw_right")
	input.power = power
	input.yaw = yaw
	input.roll = roll
	input.pitch = pitch


func simulate_action_event(action_name: String, action_pressed: bool) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = action_pressed
	return event
