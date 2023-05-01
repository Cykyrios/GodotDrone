extends PanelContainer
class_name TimeTable


var vbox: VBoxContainer
var grid: GridContainer
var label_theme: Theme

var laps := 0


func _ready() -> void:
	vbox = VBoxContainer.new()
	vbox.set("custom_constants/separation", 80)
	add_child(vbox)
	grid = GridContainer.new()
	grid.columns = 2
	grid.set("custom_constants/h_separation", 40)
	grid.set("custom_constants/v_separation", 10)
	grid.size_flags_horizontal = grid.SIZE_EXPAND
	grid.size_flags_horizontal = grid.SIZE_SHRINK_CENTER
	grid.size_flags_vertical = grid.SIZE_EXPAND
	grid.size_flags_vertical = grid.SIZE_SHRINK_CENTER
	vbox.add_child(grid)
	var button := Button.new()
	button.text = "Dismiss"
	vbox.add_child(button)
	var _discard = button.pressed.connect(_on_button_pressed)

	label_theme = preload("res://GUI/timer_theme.tres")
	add_labels("Lap", "Time")

	modulate = Color(1, 1, 1, 0.8)
	self_modulate = Color(1, 1, 1, 0.6)

	_discard = Global.game_mode_changed.connect(_on_game_mode_changed)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func add_lap(time: LapTimer) -> void:
	laps += 1
	add_labels("%d" % [laps], time.get_time_string())


func add_labels(lap: String, time: String) -> void:
	var label := Label.new()
	label.text = lap
	label.theme = label_theme
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grid.add_child(label)
	label = Label.new()
	label.text = time
	label.theme = label_theme
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grid.add_child(label)


func add_total_time(time: String) -> void:
	add_labels("Total", time)


func delete() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	queue_free()


func _on_button_pressed() -> void:
	delete()


func _on_game_mode_changed(mode) -> void:
	if mode != Global.GameMode.RACE:
		delete()


func _on_race_state_changed(state: int) -> void:
	if state == Global.RaceState.START:
		delete()
