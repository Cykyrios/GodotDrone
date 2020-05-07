extends Node

class_name RadioController

signal reset_requested
signal mode_changed
signal arm_input
signal disarm_input


export (NodePath) var target_path = null
var target = null

var input = [0.0, 0.0, 0.0, 0.0]

var axis_bindings = []


func _ready():
	target = get_node(target_path)
	
	var dict_list = Global.action_dict
	for dict in dict_list:
		if dict["type"] == "axis":
			axis_bindings.append(dict)
	
	connect("reset_requested", target, "_on_reset")
	connect("mode_changed", target.flight_controller, "_on_cycle_flight_modes")
	connect("arm_input", target.flight_controller, "_on_arm_input")
	connect("disarm_input", target.flight_controller, "_on_disarm_input")


func _input(event):
	if event is InputEventJoypadMotion:
		var dict = null
		for i in range(axis_bindings.size()):
			if event.axis == axis_bindings[i]["axis"]:
				dict = axis_bindings[i]
				var action = dict["action"]
				var bound_low = dict["min"]
				var bound_high = dict["max"]
				var axis_value = event.axis_value
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


func _physics_process(delta):
	read_input()
	
	if target is Drone:
		target.flight_controller.input = input


func read_input():
	var power = (Input.get_action_strength("throttle_up") - Input.get_action_strength("throttle_down") + 1) / 2
	var pitch = Input.get_action_strength("pitch_up") - Input.get_action_strength("pitch_down")
	var roll = Input.get_action_strength("roll_right") - Input.get_action_strength("roll_left")
	var yaw = Input.get_action_strength("yaw_right") - Input.get_action_strength("yaw_left")
#	print("Pow: %6.3f ptc: %6.3f rol: %6.3f yaw: %6.3f" % [power, pitch, roll, yaw])
	input = [power, yaw, roll, pitch]


func simulate_action_event(action_name: String, action_pressed: bool) -> InputEventAction:
	var event = InputEventAction.new()
	event.action = action_name
	event.pressed = action_pressed
	return event
