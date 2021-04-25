tool
extends Spatial
class_name Track


signal race_state_changed(state)


export (bool) var edit_track := false setget set_edit_track
export (int) var selected_checkpoint := -1 setget set_selected_checkpoint
export (String, MULTILINE) var course

var checkpoints := []
var current_checkpoint: Checkpoint = null
var current := 0

export (int, 1, 100) var laps := 3
var current_lap := 1
var lap_start := 0
var lap_end := 0
var timers := []
var timer_label: Label = null

var race_state: int = Global.RaceState.START setget set_race_state
var countdown_timer: Timer = null
var countdown_label: Label = null
var countdown_step := 0
var end_label: Label = null

var has_launchpad := false
var launch_areas := []

var replay_path := ""
var ghosts := []
var replay_recorder := []
var record_replay := false


func _ready() -> void:
	if Engine.editor_hint:
		return
	
	pause_mode = Node.PAUSE_MODE_STOP
	
	setup_countdown()
	setup_timer_label()
	setup_end_label()
	
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
	for area in launch_areas:
		var _discard = area.connect("body_exited", self, "_on_body_exited_launchpad")
	
	replay_path = "%s/%s" % [Global.replay_dir, filename.replace(".tscn", ".rpl").split("/")[-1]]
	ghosts.clear()
	for _i in range(3):
		ghosts.append(Ghost.new())


func _process(_delta: float) -> void:
	if not Engine.editor_hint:
		if race_state == Global.RaceState.RACE:
			update_timer_label()


func update_checkpoints() -> void:
	checkpoints.clear()
	for child in get_children():
		if child is Gate:
			for c in child.get_children():
				if c is Checkpoint:
					checkpoints.append(c)
		elif child is Checkpoint:
			checkpoints.append(child)


func update_course() -> void:
	if course == "":
		course = []
		for i in range(checkpoints.size()):
			course.append(str(i))
	else:
		course = course.replace("\n", ",")
		course = course.replace(" ", "")
		var temp_course: Array = course.split(",")
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


func update_launch_areas() -> void:
	for child in get_children():
		if child is Launchpad:
			for area in child.launch_areas:
				launch_areas.append(area)
	has_launchpad = not launch_areas.empty()


func set_edit_track(edit: bool) -> void:
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


func set_selected_checkpoint(selected: int) -> void:
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


func set_race_state(state: int) -> void:
	race_state = state
	emit_signal("race_state_changed", race_state)


func _on_checkpoint_passed(cp: Checkpoint) -> void:
	if cp != current_checkpoint:
		return
	
	current_checkpoint.set_active(false)
	if current >= lap_end:
		if current_lap < laps:
			end_current_lap()
			start_next_lap()
		elif current == course.size() - 1:
			end_current_lap()
			end_race()
		else:
			activate_next_checkpoint()
	else:
		activate_next_checkpoint()


func end_current_lap() -> void:
	timers[current_lap - 1].stop()
	var time: Dictionary = timers[current_lap - 1].get_minute_second_decimal()
	print("Lap %d/%d: %02d:%02d.%02d" % [current_lap, laps, time["minute"], time["second"], time["decimal"]])


func start_next_lap() -> void:
	if current >= lap_end and current_lap < laps:
		current_lap += 1
		current = lap_start - 1
	activate_next_checkpoint()
	if race_state == Global.RaceState.RACE:
		timers[current_lap - 1].start()


func activate_next_checkpoint() -> void:
	current += 1
	var new_cp := [course[current], false]
	if new_cp[0].ends_with("b"):
		new_cp[0] = new_cp[0].rstrip("b")
		new_cp[1] = true
	current_checkpoint = checkpoints[new_cp[0].to_int()]
	current_checkpoint.set_backward(new_cp[1])
	current_checkpoint.set_active(true)


func end_race() -> void:
	stop_timers()
	self.race_state = Global.RaceState.END
	update_timer_label()
	print("Finished!")
	display_end_label()
	stop_recording_replay(true)
	check_best_time()


func reset_track() -> void:
	stop_countdown()
	stop_timers()
	reset_timers()
	
	if current_checkpoint != null:
		current_checkpoint.set_active(false)
	current_lap = 1
	current = -1
	activate_next_checkpoint()


func setup_countdown() -> void:
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


func setup_end_label() -> void:
	end_label = Label.new()
	add_child(end_label)
	end_label.theme = load("res://GUI/ThemeCountdown.tres")
	end_label.align = Label.ALIGN_CENTER
	end_label.valign = Label.VALIGN_CENTER
	end_label.set_anchors_and_margins_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	end_label.visible = false


func setup_timer_label() -> void:
	timer_label = Label.new()
	add_child(timer_label)
	timer_label.theme = load("res://GUI/ThemeTimer.tres")
	timer_label.align = Label.ALIGN_LEFT
	timer_label.valign = Label.VALIGN_TOP
	timer_label.set_anchors_and_margins_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE)
	timer_label.visible = false


func start_countdown() -> void:
	self.race_state = Global.RaceState.START
	countdown_step = 0
	timer_label.visible = true
	update_countdown(countdown_step)
	update_timer_label()
	for ghost in ghosts:
		ghost.start_replay()


func update_countdown(step: int = 0) -> void:
	if step != countdown_step:
		countdown_step = step
	if step <= 0:
		countdown_timer.start(2)
		if step == -1:
			countdown_label.visible = true
			countdown_label.text = "False Start!"
	elif step <= 4:
		countdown_timer.start(1)
		countdown_label.visible = true
		if step <= 3:
			countdown_label.text = "%d" % [3 - step + 1]
		elif step == 4:
			countdown_label.text = "GO!"
			start_race()
	countdown_label.set_anchors_and_margins_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


func stop_countdown() -> void:
	countdown_timer.stop()
	countdown_label.visible = false


func update_timer_label() -> void:
	if race_state == Global.RaceState.START:
		timer_label.text = "Prev. lap: 00:00.00 (0)\nCurr. lap: 00:00.00 (0)\nTotal: 00:00.00"
	elif race_state == Global.RaceState.RACE or race_state == Global.RaceState.END:
		var total_time := 0.0
		for timer in timers:
			total_time += timer.time
		timer_label.text = "Prev. lap: %s (%d)\nCurr. lap: %s (%d)\nTotal: %s" \
				% [timers[current_lap - 2].get_time_string(), current_lap - 1,
				timers[current_lap - 1].get_time_string(), current_lap,
				timers[0].get_time_string(total_time)]


func start_race() -> void:
	timers[0].start()
	self.race_state = Global.RaceState.RACE
	timer_label.visible = true


func stop_race() -> void:
	stop_timers()
	reset_timers()
	stop_countdown()
	timer_label.visible = false
	for ghost in ghosts:
		ghost.stop_replay()


func stop_timers() -> void:
	for timer in timers:
		timer.stop()


func reset_timers() -> void:
	for timer in timers:
		timer.reset()


func get_random_launch_area() -> LaunchArea:
	if not launch_areas.empty():
		return launch_areas[randi() % launch_areas.size()]
	else:
		return null


func _on_countdown_timer_timeout() -> void:
	countdown_label.visible = false
	if countdown_step >= 0:
		countdown_step += 1
		update_countdown(countdown_step)
	else:
		stop_countdown()


func _on_body_exited_launchpad(body: Node) -> void:
	if body is Drone and Global.game_mode == Global.GameMode.RACE \
			and race_state == Global.RaceState.START:
		# False start check
		if not countdown_timer.is_stopped() and (countdown_step > 0 \
				or countdown_step == 0 and countdown_timer.time_left < countdown_timer.wait_time - 0.05):
			stop_countdown()
			update_countdown(-1)


func display_end_label() -> void:
	end_label.text = "Finished!"
	end_label.set_anchors_and_margins_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	end_label.visible = true
	var timer := Timer.new()
	add_child(timer)
	timer.start(2)
	yield(timer, "timeout")
	end_label.visible = false
	remove_child(timer)
	timer.queue_free()
	
	if Global.game_mode == Global.GameMode.RACE and timers[0].time >= 1:
		timer_label.visible = false
		display_time_table()


func display_time_table() -> void:
	var total_time := 0.0
	var time_table := TimeTable.new()
	add_child(time_table)
	var _discard = connect("race_state_changed", time_table, "_on_race_state_changed")
	for i in timers.size():
		time_table.add_lap(timers[i])
		total_time += timers[i].time
	time_table.add_total_time(timers[0].get_time_string(total_time))


func load_replays() -> void:
	var file := File.new()
	for i in range(3):
		if file.open(replay_path, File.READ) == OK:
			if ghosts[i]:
				ghosts[i].queue_free()
			ghosts[i] = Ghost.new()
			match i:
				0:
					ghosts[i].type = Ghost.Type.PREVIOUS
				1:
					ghosts[i].type = Ghost.Type.RACE
				2:
					ghosts[i].type = Ghost.Type.LAP
			ghosts[i].replay_path = replay_path
			ghosts[i].read_replay()
			add_child(ghosts[i])


func initialize_replay(drone: Drone) -> void:
	if not drone.is_connected("transform_updated", self, "_on_drone_transform_updated"):
		var _discard = drone.connect("transform_updated", self, "_on_drone_transform_updated")
	delete_previous_replay()
	record_replay = true
	# Write drone scene path at the beginning of the replay file
	_on_drone_transform_updated(drone.filename, true)


func delete_previous_replay() -> void:
	replay_recorder.clear()
	var dir := Directory.new()
	if dir.file_exists(replay_path):
		var _discard = dir.remove(replay_path)


func _on_drone_transform_updated(xform_string: String, init: bool = false) -> void:
	if record_replay:
		if init:
			var file := File.new()
			var err = file.open(replay_path, File.WRITE)
			if err == OK:
				file.store_line(xform_string)
				file.close()
		else:
			replay_recorder.append(xform_string)
			if replay_recorder.size() >= 1000:
				write_replay(1000)


func write_replay(lines: int) -> void:
	var file := File.new()
	var err = file.open(replay_path, File.READ_WRITE)
	if err == OK:
		file.seek_end()
		for i in range(lines):
			file.store_line(replay_recorder[i])
		file.close()
		replay_recorder.clear()


func stop_recording_replay(save: bool = false) -> void:
	if record_replay:
		record_replay = false
		if replay_recorder.size() > 0:
			write_replay(replay_recorder.size())
			replay_recorder.clear()
		var dir := Directory.new()
		if save:
			var _discard = dir.rename(replay_path, replay_path.replace(".rpl", "_prev.rpl"))
		else:
			var _discard = dir.remove(replay_path)


func check_best_time() -> void:
	var total_time := 0.0
	for timer in timers:
		total_time += timer.time
	var file := File.new()
	var track_name := replay_path.replace(".rpl", "").split("/")[-1]
	var record_exists := false
	var new_record := false
	if file.open(Global.highscore_path, File.READ) == OK:
		while not file.eof_reached():
			if file.get_line() == track_name:
				record_exists = true
				if total_time < float(file.get_line()):
					new_record = true
				break
		file.close()
		if new_record or not record_exists:
			write_new_record(total_time)
			var dir := Directory.new()
			var _discard = dir.rename(replay_path.replace(".rpl", "_prev.rpl"),
					replay_path.replace(".rpl", "_race.rpl"))


func write_new_record(time: float) -> void:
	var track_name := replay_path.replace(".rpl", "").split("/")[-1]
	var array := []
	var file := File.new()
	if file.open(Global.highscore_path, File.READ) == OK:
		while not file.eof_reached():
			array.append(file.get_line())
		file.close()
		var _discard = file.open(Global.highscore_path, File.WRITE)
		var idx := array.find(track_name)
		if idx == -1:
			for element in array:
				if element != "":
					file.store_line(element)
			file.store_line(track_name)
			file.store_line(String(time))
		else:
			for i in range(idx + 1):
				if array[i] != "":
					file.store_line(array[i])
			file.store_line(String(time))
			for i in range(idx + 2, array.size()):
				if array[i] != "":
					file.store_line(array[i])
		file.close()
