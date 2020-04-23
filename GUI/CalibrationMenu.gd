extends Control


onready var label_action = $VBoxContainer/LabelAction

var calibration_step = -1
var axes = []
var throttle = []
var yaw = []
var pitch = []
var roll = []

var calibration_done = false

signal calibration_done


func _ready():
	$VBoxContainer/ButtonCancel.connect("pressed", self, "_on_cancel_pressed")
	connect("calibration_done", self, "_on_calibration_done")
	
	go_to_next_step()


func _process(delta):
	var next_step_ready = true
	if calibration_step == 0 and axes.size() == 4:
		for i in range(4):
			if abs(Input.get_joy_axis(0, i)) < 0.5:
				next_step_ready = false
				break
	elif calibration_step == 1:
		for i in range(4):
			if abs(Input.get_joy_axis(0, i)) > 0.2:
				next_step_ready = false
				break
	else:
		next_step_ready = false
	if next_step_ready:
		go_to_next_step()


func _input(event):
	if event is InputEventJoypadMotion:
		if calibration_step == 0:
			if abs(event.axis_value) > 0.9:
				if axes.find(event.axis) < 0:
					axes.append(event.axis)
		elif calibration_step == 2:
			# Throttle axis
			if axes.find(event.axis) >= 0 and abs(event.axis_value) > 0.9:
				throttle.append(event.axis)
				throttle.append(event.axis_value)
				go_to_next_step()
		elif calibration_step == 3:
			if event.axis == throttle[0]:
				if abs(event.axis_value + throttle[1]) < 0.2:
					go_to_next_step()
		elif calibration_step == 4:
			if event.axis == throttle[0] and abs(event.axis_value) < 0.2:
				go_to_next_step()
		elif calibration_step == 5:
			# Yaw axis
			if axes.find(event.axis) >= 0 and abs(event.axis_value) > 0.9:
				yaw.append(event.axis)
				yaw.append(event.axis_value)
				go_to_next_step()
		elif calibration_step == 6:
			if event.axis == yaw[0]:
				if abs(event.axis_value + yaw[1]) < 0.2:
					go_to_next_step()
		elif calibration_step == 7:
			if event.axis == yaw[0] and abs(event.axis_value) < 0.2:
				go_to_next_step()
		elif calibration_step == 8:
			# Pitch axis
			if axes.find(event.axis) >= 0 and abs(event.axis_value) > 0.9:
				pitch.append(event.axis)
				pitch.append(event.axis_value)
				go_to_next_step()
		elif calibration_step == 9:
			if event.axis == pitch[0]:
				if abs(event.axis_value + pitch[1]) < 0.2:
					go_to_next_step()
		elif calibration_step == 10:
			if event.axis == pitch[0] and abs(event.axis_value) < 0.2:
				go_to_next_step()
		elif calibration_step == 11:
			# Roll axis
			if axes.find(event.axis) >= 0 and abs(event.axis_value) > 0.9:
				roll.append(event.axis)
				roll.append(event.axis_value)
				go_to_next_step()
		elif calibration_step == 12:
			if event.axis == roll[0]:
				if abs(event.axis_value + roll[1]) < 0.2:
					go_to_next_step()
		elif calibration_step == 13:
			if event.axis == roll[0] and abs(event.axis_value) < 0.2:
				go_to_next_step()
		
		elif calibration_done:
			var string = ""
			if event.axis == throttle[0]:
				string = "Throttle"
			elif event.axis == yaw[0]:
				string = "Yaw"
			elif event.axis == pitch[0]:
				string = "Pitch"
			elif event.axis == roll[0]:
				string = "Roll"
			print("%s: %5.2f" % [string, event.axis_value])


func go_to_next_step():
	calibration_step += 1
	
	match calibration_step:
		0:
			label_action.text = "Move sticks to corners"
		1:
			label_action.text = "Center sticks"
		2:
			label_action.text = "Move throttle up"
		3:
			label_action.text = "Move throttle down"
		4:
			label_action.text = "Center throttle"
		5:
			label_action.text = "Move yaw left"
		6:
			label_action.text = "Move yaw right"
		7:
			label_action.text = "Center yaw"
		8:
			label_action.text = "Move pitch up"
		9:
			label_action.text = "Move pitch down"
		10:
			label_action.text = "Center pitch"
		11:
			label_action.text = "Move roll left"
		12:
			label_action.text = "Move roll right"
		13:
			label_action.text = "Center roll"
		_:
			label_action.text = "Calibration successful"
			emit_signal("calibration_done")
		
	print("Current step: %d" % [calibration_step])


func _on_calibration_done():
	calibration_done = true
#	InputMap.action_erase_events("increase_power")
#	InputMap.action_add_event("increase_power", )


func reset_calibration():
	calibration_step = 0


func _on_cancel_pressed():
	reset_calibration()
