extends Node

class_name FlightController

var basis : Basis
var basis_prev : Basis
var pos : Vector3
var pos_prev : Vector3
var lin_vel : Vector3
var ang_vel : Vector3

var props = []
var input = [0, 0, 0, 0]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _physics_process(delta):
	pass


func _input(event):
	# used to change modes etc.?
	pass


func set_props(prop_array):
	props = prop_array


func read_position(p : Vector3, b : Basis):
	pos_prev = pos
	pos = p
	basis_prev = basis
	basis = b


func read_velocity(lin_v : Vector3, ang_v : Vector3):
	lin_vel = lin_v
	ang_vel = ang_v


func read_input(power_inp, pitch_inp, roll_inp, yaw_inp):
	input = [power_inp, pitch_inp, roll_inp, yaw_inp]


func update_control():
	change_power(input[0])
	change_pitch(input[1])
	change_roll(input[2])
	change_yaw(input[3])
	
	for prop in props:
		prop.update_thrust()


func change_power(p):
	for prop in props:
		prop.set_power(p - 0.3)


func change_pitch(p):
	var pitch_change = p / 100
	for i in range(4):
		if i < 2:
			props[i].set_power(props[i].get_power() + pitch_change)
		else:
			props[i].set_power(props[i].get_power() - pitch_change)


func change_roll(r):
	var roll_change = r / 100
	for i in range(4):
		if i == 0 or i == 3:
			props[i].set_power(props[i].get_power() + roll_change)
		else:
			props[i].set_power(props[i].get_power() - roll_change)


func change_yaw(y):
	var yaw_change = y
	for i in range(4):
		if i == 0 or i == 2:
			props[i].set_power(props[i].get_power() + yaw_change)
		else:
			props[i].set_power(props[i].get_power() - yaw_change)
