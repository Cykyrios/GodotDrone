tool
extends Spatial
class_name Track


export (bool) var edit_track = false setget set_edit_track
export (int) var selected_checkpoint = -1 setget set_selected_checkpoint
export (String, MULTILINE) var course

var checkpoints = []
var current_checkpoint = null
var current = 0

export (int, 1, 100) var laps = 3
var current_lap = 1
var lap_start = 0
var lap_end = 0
var timers := []

var countdown_timer: Timer = null
var countdown_label: Label = null
var countdown_step := 0

var has_launchpad := false
var launch_areas := []


func _ready():
	if Engine.editor_hint:
		return
	
	setup_countdown()
	
	set_selected_checkpoint(-1)
	set_edit_track(false)
	
	update_checkpoints()
	
	for cp in checkpoints:
		var _discard = cp.connect("passed", self, "_on_checkpoint_passed")
	
	update_course()
	
	for _i in range(laps):
		timers.append(LapTimer.new())
		add_child(timers[-1])
	
	update_launch_areas()


func update_checkpoints():
	checkpoints.clear()
	for child in get_children():
		if child is Gate:
			for c in child.get_children():
				if c is Checkpoint:
					checkpoints.append(c)
		elif child is Checkpoint:
			checkpoints.append(child)


func update_course():
	if course == "":
		course = []
		for i in range(checkpoints.size()):
			course.append(str(i))
	else:
		course = course.replace("\n", ",")
		course = course.replace(" ", "")
		var temp_course = course.split(",")
		course = []
		for i in range(temp_course.size()):
			course.append(temp_course[i])
		while course.find("") != -1:
			course.erase("")
	
	if !course.has("lap_start"):
		course.push_front("lap_start")
	if !course.has("lap_end"):
		course.push_back("lap_end")
	lap_start = course.find("lap_start")
	lap_end = course.find("lap_end")
	if lap_start != -1:
		course.remove(lap_start)
		lap_end -= 1
	else:
		lap_start = 0
	if lap_end != -1:
		course.remove(lap_end)
		lap_end -= 1
	else:
		lap_end = course.size() - 1
	
	reset_track()


func update_launch_areas():
	for child in get_children():
		if child is Launchpad:
			for area in child.launch_areas:
				launch_areas.append(area)
	has_launchpad = not launch_areas.empty()


func set_edit_track(edit : bool):
	if !Engine.editor_hint:
		return
	edit_track = edit
	if edit_track:
		update_checkpoints()
	for cp in checkpoints:
		cp.set_area_visible(edit_track)
		cp.mat.set_shader_param("Editor", edit_track)
		cp.mat.set_shader_param("Selected", false)
	if !edit_track:
		checkpoints.clear()
		selected_checkpoint = -1


func set_selected_checkpoint(selected : int):
	if !Engine.editor_hint:
		return
	var size = checkpoints.size()
	if size == 0:
		selected_checkpoint = -1
		return
	elif selected >= size:
		return
	elif selected < -1:
		checkpoints[selected_checkpoint].set_selected(false)
		return
	checkpoints[selected_checkpoint].set_selected(false)
	selected_checkpoint = selected
	checkpoints[selected_checkpoint].set_selected(true)


func _on_checkpoint_passed(cp):
	if cp != current_checkpoint:
		return
	
	current_checkpoint.set_active(false)
	if current == course.size() - 1:
		timers[current_lap - 1].stop()
		var time = timers[current_lap - 1].get_minute_second_decimal()
		print("Lap %d/%d: %02d:%02d.%03d" % [current_lap, laps, time["minute"], time["second"], time["millisecond"]])
		if current_lap == laps:
			print("Finished!")
		else:
			activate_next_checkpoint()
			timers[current_lap - 1].start()
	else:
		activate_next_checkpoint()


func activate_next_checkpoint():
	if current >= lap_end and current_lap < laps:
		current_lap += 1
		current = lap_start
	else:
		current += 1
	var new_cp = [course[current], false]
	if new_cp[0].ends_with("b"):
		new_cp[0] = new_cp[0].rstrip("b")
		new_cp[1] = true
	current_checkpoint = checkpoints[new_cp[0].to_int()]
	current_checkpoint.set_backward(new_cp[1])
	current_checkpoint.set_active(true)


func reset_track():
	stop_countdown()
	stop_timers()
	
	if current_checkpoint != null:
		current_checkpoint.set_active(false)
	current_lap = 1
	current = -1
	activate_next_checkpoint()


func setup_countdown():
	countdown_timer = Timer.new()
	add_child(countdown_timer)
	countdown_timer.one_shot = true
	var _discard = countdown_timer.connect("timeout", self, "_on_countdown_timer_timeout")
	
	countdown_label = Label.new()
	add_child(countdown_label)
	countdown_label.theme = load("res://GUI/ThemeCountdown.tres")
	countdown_label.align = Label.ALIGN_CENTER
	countdown_label.valign = Label.VALIGN_CENTER
	countdown_label.set_anchors_and_margins_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	countdown_label.visible = false


func start_countdown():
	countdown_step = 0
	update_countdown(countdown_step)


func update_countdown(step: int = 0):
	if step <= 0:
		countdown_timer.start(2)
	elif step <= 4:
		countdown_timer.start(1)
		countdown_label.visible = true
		if step <= 3:
			countdown_label.text = "%d" % [3 - step + 1]
		elif step == 4:
			countdown_label.text = "GO!"
			start_race()
		countdown_label.set_anchors_and_margins_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


func stop_countdown():
	countdown_timer.stop()
	countdown_label.visible = false


func start_race():
	timers[0].start()


func stop_race():
	stop_timers()


func stop_timers():
	for timer in timers:
		timer.stop()
		timer.reset()


func get_random_launch_area() -> LaunchArea:
	if not launch_areas.empty():
		return launch_areas[randi() % launch_areas.size()]
	else:
		return null


func _on_countdown_timer_timeout():
	countdown_label.visible = false
	countdown_step += 1
	update_countdown(countdown_step)
