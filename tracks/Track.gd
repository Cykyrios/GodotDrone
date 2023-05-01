@tool
class_name Track
extends Node3D


signal race_state_changed(state)


@export var edit_track := false :
	set(edit):
		if !Engine.is_editor_hint():
			return
		edit_track = edit
		if edit_track:
			update_checkpoints()
		for cp in checkpoints:
			cp.area_visible = edit_track
			cp.mat.set_shader_parameter("Editor", edit_track)
			cp.mat.set_shader_parameter("Selected", false)
		if !edit_track:
			checkpoints.clear()
			selected_checkpoint = -1
@export var selected_checkpoint := -1 :
	set(selected):
		if !Engine.is_editor_hint():
			return
		var size := checkpoints.size()
		if size == 0:
			selected_checkpoint = -1
			return
		elif selected >= size:
			return
		elif selected < -1:
			checkpoints[selected_checkpoint].selected = false
			return
		checkpoints[selected_checkpoint].selected = false
		selected_checkpoint = selected
		checkpoints[selected_checkpoint].selected = true
@export_multiline var course := ""
var course_array: Array[String] = []

var checkpoints := []
var current_checkpoint: Checkpoint = null
var current := 0

@export_range(1, 100) var laps := 3
var current_lap := 1
var lap_start := 0
var lap_end := 0
var timers := []
var timer_label: Label = null

var race_state: int = Global.RaceState.START :
	set(state):
		race_state = state
		race_state_changed.emit(race_state)
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
	if Engine.is_editor_hint():
		return

	process_mode = PROCESS_MODE_PAUSABLE

	setup_countdown()
	setup_timer_label()
	setup_end_label()

	selected_checkpoint = -1
	edit_track = false

	update_checkpoints()

	for cp in checkpoints:
		var _discard = cp.passed.connect(_on_checkpoint_passed)

	update_course()

	for _i in range(laps):
		timers.append(LapTimer.new())
		add_child(timers[-1])

	update_launch_areas()
	for area in launch_areas:
		var _discard = area.body_exited.connect(_on_body_exited_launchpad)

	replay_path = "%s/%s" % [Global.replay_dir, scene_file_path.replace(".tscn", ".rpl").split("/")[-1]]
	ghosts.clear()
	for _i in range(5):
		ghosts.append(Ghost.new())


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
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
	course_array.clear()
	if course == "":
		course_array = []
		for i in range(checkpoints.size()):
			course_array.append(str(i))
	else:
		course = course.replace("\n", ",")
		course = course.replace(" ", "")
		var temp_course := course.split(",")
		course_array = []
		for i in range(temp_course.size()):
			course_array.append(temp_course[i])
		while course_array.find("") != -1:
			course_array.erase("")

	if !course_array.has("lap_start"):
		course_array.push_front("lap_start")
	if !course_array.has("lap_end"):
		course_array.push_back("lap_end")
	lap_start = course_array.find("lap_start")
	lap_end = course_array.find("lap_end")
	if lap_start != -1:
		course_array.remove_at(lap_start)
		lap_end -= 1
	else:
		lap_start = 0
	if lap_end != -1:
		course_array.remove_at(lap_end)
		lap_end -= 1
	else:
		lap_end = course_array.size() - 1

	reset_track()


func update_launch_areas() -> void:
	for child in get_children():
		if child is Launchpad:
			for area in child.launch_areas:
				launch_areas.append(area)
	has_launchpad = not launch_areas.is_empty()


func _on_checkpoint_passed(cp: Checkpoint) -> void:
	if cp != current_checkpoint:
		return

	current_checkpoint.active = false
	if current >= lap_end:
		if current_lap < laps:
			end_current_lap()
			start_next_lap()
		elif current == course_array.size() - 1:
			end_current_lap()
			end_race()
		else:
			activate_next_checkpoint()
	else:
		activate_next_checkpoint()


func end_current_lap() -> void:
	timers[current_lap - 1].stop()
	var time: Dictionary = timers[current_lap - 1].get_minute_second_decimal()
	print("Lap %d/%d: %02d:%02d.%02d"
			% [current_lap, laps, time["minute"], time["second"], time["decimal"]])


func start_next_lap() -> void:
	if current >= lap_end and current_lap < laps:
		current_lap += 1
		current = lap_start - 1
	activate_next_checkpoint()
	if race_state == Global.RaceState.RACE:
		timers[current_lap - 1].start()


func activate_next_checkpoint() -> void:
	current += 1
	var new_cp: Array = [course_array[current], false]
	if new_cp[0].ends_with("b"):
		new_cp[0] = new_cp[0].rstrip("b")
		new_cp[1] = true
	current_checkpoint = checkpoints[new_cp[0].to_int()]
	current_checkpoint.backward = new_cp[1]
	current_checkpoint.active = true


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
	stop_recording_replay(true, false)
	reset_timers()

	if current_checkpoint != null:
		current_checkpoint.active = false
	current_lap = 1
	current = -1
	activate_next_checkpoint()


func setup_countdown() -> void:
	countdown_timer = Timer.new()
	add_child(countdown_timer)
	countdown_timer.one_shot = true
	var _discard = countdown_timer.timeout.connect(_on_countdown_timer_timeout)

	countdown_label = Label.new()
	add_child(countdown_label)
	countdown_label.theme = load("res://GUI/countdown_theme.tres")
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	countdown_label.visible = false


func setup_end_label() -> void:
	end_label = Label.new()
	add_child(end_label)
	end_label.theme = load("res://GUI/countdown_theme.tres")
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	end_label.visible = false


func setup_timer_label() -> void:
	timer_label = Label.new()
	add_child(timer_label)
	timer_label.theme = load("res://GUI/timer_theme.tres")
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	timer_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE)
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
	countdown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


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
	if record_replay:
		stop_recording_replay(true, false)
	for ghost in ghosts:
		ghost.stop_replay()


func stop_timers() -> void:
	for timer in timers:
		timer.stop()


func reset_timers() -> void:
	for timer in timers:
		timer.reset()


func get_random_launch_area() -> LaunchArea:
	if not launch_areas.is_empty():
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
#	if body is Drone and Global.game_mode == Global.GameMode.RACE \
	if Global.game_mode == Global.GameMode.RACE \
			and race_state == Global.RaceState.START:
		# False start check
		if not countdown_timer.is_stopped() and (countdown_step > 0 \
				or countdown_step == 0 and countdown_timer.time_left < countdown_timer.wait_time - 0.05):
			stop_countdown()
			update_countdown(-1)


func display_end_label() -> void:
	end_label.text = "Finished!"
	end_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	end_label.visible = true
	var timer := Timer.new()
	add_child(timer)
	timer.start(2)
	await timer.timeout
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
	var _discard = race_state_changed.connect(time_table._on_race_state_changed)
	for i in timers.size():
		time_table.add_lap(timers[i])
		total_time += timers[i].time
	time_table.add_total_time(timers[0].get_time_string(total_time))


func load_replays() -> void:
	for i in range(5):
		var file := FileAccess.open(replay_path, FileAccess.READ)
		if file:
			if ghosts[i]:
				ghosts[i].queue_free()
			ghosts[i] = Ghost.new()
			match i:
				0:
					ghosts[i].type = Ghost.Type.PREVIOUS
				1:
					ghosts[i].type = Ghost.Type.GOLD
				2:
					ghosts[i].type = Ghost.Type.SILVER
				3:
					ghosts[i].type = Ghost.Type.BRONZE
				4:
					ghosts[i].type = Ghost.Type.ABORTED
			ghosts[i].replay_path = replay_path
			ghosts[i].read_replay()
			add_child(ghosts[i])
			file = null


func initialize_replay(drone: Drone) -> void:
	if not drone.transform_updated.is_connected(_on_drone_transform_updated):
		var _discard = drone.transform_updated.connect(_on_drone_transform_updated)
	delete_previous_replay()
	record_replay = true
	# Write drone scene path at the beginning of the replay file
	_on_drone_transform_updated(drone.scene_file_path, true)


func delete_previous_replay() -> void:
	replay_recorder.clear()
	var dir := DirAccess.open("")
	if dir.file_exists(replay_path):
		var _discard = dir.remove(replay_path)


func _on_drone_transform_updated(xform_string: String, init: bool = false) -> void:
	if record_replay:
		if init:
			var file := FileAccess.open(replay_path, FileAccess.WRITE)
			if file:
				file.store_line(xform_string)
				file = null
		else:
			replay_recorder.append(xform_string)
			if replay_recorder.size() >= 1000:
				write_replay(1000)


func write_replay(lines: int) -> void:
	var file := FileAccess.open(replay_path, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		for i in range(lines):
			file.store_line(replay_recorder[i])
		file = null
		replay_recorder.clear()


func stop_recording_replay(save: bool = false, race_completed: bool = true) -> void:
	if record_replay:
		record_replay = false
		if replay_recorder.size() > 0:
			write_replay(replay_recorder.size())
			replay_recorder.clear()
		var dir := DirAccess.open("")
		if save:
			var replace := "prev"
			if race_completed == false:
				replace = "aborted"
			var _discard = dir.rename(replay_path, replay_path.replace(".rpl", "_%s.rpl" % [replace]))
		else:
			var _discard = dir.remove(replay_path)


func check_best_time() -> void:
	var total_time := 0.0
	for timer in timers:
		total_time += timer.time
	var track_name := replay_path.replace(".rpl", "").split("/")[-1]
	var record_exists := false
	var new_record := 0
	var file := FileAccess.open(Global.highscore_path, FileAccess.READ)
	if file:
		while not file.eof_reached():
			var line := file.get_line()
			if line == track_name:
				record_exists = true
				while new_record < 3:
					line = file.get_line()
					if line.begins_with("Track") or line == "":
						new_record = 3
						break
					if (line as float) < 0.1 or total_time < (line as float):
						break
					else:
						new_record += 1
				break
		file = null
		if new_record < 3 or not record_exists:
			write_new_record(new_record, total_time)
			var dir := DirAccess.open("")
			var replace := ["gold", "silver", "bronze"]
			for i in range(2 - new_record):
				var _discard = dir.rename(replay_path.replace(".rpl", "_%s.rpl" % [replace[-2 - i]]),
						replay_path.replace(".rpl", "_%s.rpl" % [replace[-1 - i]]))
			var _discard = dir.rename(replay_path.replace(".rpl", "_prev.rpl"),
					replay_path.replace(".rpl", "_%s.rpl" % [replace[new_record]]))


func write_new_record(pos: int, time: float) -> void:
	var track_name := replay_path.replace(".rpl", "").split("/")[-1]
	var array := []
	var file := FileAccess.open(Global.highscore_path, FileAccess.READ)
	if file:
		while not file.eof_reached():
			array.append(file.get_line())
		file = null
		file = FileAccess.open(Global.highscore_path, FileAccess.WRITE)
		if file:
			var idx := array.find(track_name)
			if idx == -1:
				for element in array:
					if element != "":
						file.store_line(element)
				file.store_line(track_name)
				file.store_line("%f" % [time])
			else:
				for i in range(idx + 1 + pos):
					if array[i] != "":
						file.store_line(array[i])
				file.store_line("%f" % [time])
				for i in range(idx + 2 + pos, array.size()):
					if array[i] != "":
						file.store_line(array[i])
			file = null
