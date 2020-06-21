extends Control


onready var title = $PanelContainer/VBoxContainer/Title
onready var label_action = $PanelContainer/VBoxContainer/LabelAction

var calibration_step = -1
var device = 0
var axes = []
var throttle = []
var yaw = []
var pitch = []
var roll = []

var calibration_done = false
var packed_popup = load("res://GUI/ConfirmationPopup.tscn")
var display_popup = false

signal calibration_done
signal back


func _ready():
	var _discard = $PanelContainer/VBoxContainer/ButtonCancel.connect("pressed", self, "_on_cancel_pressed")
	_discard = connect("calibration_done", self, "_on_calibration_done")
	
	reset_calibration()


func _process(_delta):
	var next_step_ready = true
	if calibration_step == 0 and axes.size() == 4:
		for i in range(4):
			if abs(Input.get_joy_axis(device, i)) < 0.5:
				next_step_ready = false
				break
	elif calibration_step == 1:
		for i in range(4):
			if abs(Input.get_joy_axis(device, i)) > 0.2:
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
				if axes.size() == 0:
					device = event.device
					title.text = "Calibrating %s..." % [Input.get_joy_name(device)]
				elif event.device != device and !display_popup:
					display_popup = true
					var popup = packed_popup.instance()
					add_child(popup)
					popup.set_text("Please input axes from %s." % [Input.get_joy_name(device)])
					popup.set_buttons("OK")
					popup.show_modal(true)
					yield(popup, "validated")
					popup.queue_free()
					display_popup = false
				if axes.find(event.axis) < 0:
					axes.append(event.axis)
		elif calibration_step == 2:
			# Throttle axis
			if axes.find(event.axis) >= 0 and abs(event.axis_value) > 0.9:
				throttle.append(event.axis)
				throttle.append(event)
				go_to_next_step()
		elif calibration_step == 3:
			if event.axis == throttle[0]:
				if abs(event.axis_value + throttle[1].axis_value) < 0.2:
					throttle.append(event)
					go_to_next_step()
		elif calibration_step == 4:
			if event.axis == throttle[0] and abs(event.axis_value) < 0.2:
				go_to_next_step()
		elif calibration_step == 5:
			# Yaw axis
			if axes.find(event.axis) >= 0 and abs(event.axis_value) > 0.9:
				yaw.append(event.axis)
				yaw.append(event)
				go_to_next_step()
		elif calibration_step == 6:
			if event.axis == yaw[0]:
				if abs(event.axis_value + yaw[1].axis_value) < 0.2:
					yaw.append(event)
					go_to_next_step()
		elif calibration_step == 7:
			if event.axis == yaw[0] and abs(event.axis_value) < 0.2:
				go_to_next_step()
		elif calibration_step == 8:
			# Pitch axis
			if axes.find(event.axis) >= 0 and abs(event.axis_value) > 0.9:
				pitch.append(event.axis)
				pitch.append(event)
				go_to_next_step()
		elif calibration_step == 9:
			if event.axis == pitch[0]:
				if abs(event.axis_value + pitch[1].axis_value) < 0.2:
					pitch.append(event)
					go_to_next_step()
		elif calibration_step == 10:
			if event.axis == pitch[0] and abs(event.axis_value) < 0.2:
				go_to_next_step()
		elif calibration_step == 11:
			# Roll axis
			if axes.find(event.axis) >= 0 and abs(event.axis_value) > 0.9:
				roll.append(event.axis)
				roll.append(event)
				go_to_next_step()
		elif calibration_step == 12:
			if event.axis == roll[0]:
				if abs(event.axis_value + roll[1].axis_value) < 0.2:
					roll.append(event)
					go_to_next_step()
		elif calibration_step == 13:
			if event.axis == roll[0] and abs(event.axis_value) < 0.2:
				go_to_next_step()


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


func _on_calibration_done():
	calibration_done = true
	InputMap.action_erase_events("throttle_up")
	InputMap.action_erase_events("throttle_down")
	InputMap.action_add_event("throttle_up", throttle[1])
	InputMap.action_add_event("throttle_down", throttle[2])
	InputMap.action_erase_events("yaw_left")
	InputMap.action_erase_events("yaw_right")
	InputMap.action_add_event("yaw_left", yaw[1])
	InputMap.action_add_event("yaw_right", yaw[2])
	InputMap.action_erase_events("pitch_down")
	InputMap.action_erase_events("pitch_up")
	InputMap.action_add_event("pitch_down", pitch[1])
	InputMap.action_add_event("pitch_up", pitch[2])
	InputMap.action_erase_events("roll_left")
	InputMap.action_erase_events("roll_right")
	InputMap.action_add_event("roll_left", roll[1])
	InputMap.action_add_event("roll_right", roll[2])
	var err = save_input_map()
	if err != OK:
		var popup = packed_popup.instance()
		add_child(popup)
		popup.set_text("Write Error: Could not save calibration data to file.")
		popup.set_buttons("OK")
		popup.show_modal(true)
		yield(popup, "validated")
		popup.queue_free()
	
	yield(get_tree().create_timer(2.0), "timeout")
	emit_signal("back")


func save_input_map():
	var config = ConfigFile.new()
	var err = config.load(Controls.input_map_path)
	if err == OK or err == ERR_FILE_NOT_FOUND:
		var guid = Input.get_joy_guid(device)
		config.set_value("controls", "active_controller_guid", guid)
		config.set_value("controls", "active_controller_name", Input.get_joy_name(device))
		
		config.set_value("controls_%s" % [guid], "throttle_up", Input.get_joy_axis_string(throttle[1].axis))
		var inverted = false
		if sign(throttle[2].axis_value) < 0:
			inverted = true
		config.set_value("controls_%s" % [guid], "throttle_inverted", inverted)
		config.set_value("controls_%s" % [guid], "yaw_left", Input.get_joy_axis_string(yaw[1].axis))
		inverted = false
		if sign(yaw[2].axis_value) < 0:
			inverted = true
		config.set_value("controls_%s" % [guid], "yaw_inverted", inverted)
		config.set_value("controls_%s" % [guid], "pitch_up", Input.get_joy_axis_string(pitch[1].axis))
		inverted = false
		if sign(pitch[2].axis_value) > 0:
			inverted = true
		config.set_value("controls_%s" % [guid], "pitch_inverted", inverted)
		config.set_value("controls_%s" % [guid], "roll_left", Input.get_joy_axis_string(roll[1].axis))
		inverted = false
		if sign(roll[2].axis_value) < 0:
			inverted = true
		config.set_value("controls_%s" % [guid], "roll_inverted", inverted)
		err = config.save(Controls.input_map_path)
		if err != OK:
			Global.log_error(err, "Could not save calibration data to file.")
	else:
		Global.log_error(err, "Could not save calibration data to file.")
	return err


func reset_calibration():
	calibration_done = false
	calibration_step = -1
	axes.clear()
	throttle.clear()
	yaw.clear()
	pitch.clear()
	roll.clear()
	go_to_next_step()


func _on_cancel_pressed():
	reset_calibration()
	emit_signal("back")
