extends Node


signal game_mode_changed


enum GameMode {FREE, RACE}
enum RaceState {START, RACE, END}


var log_path := "user://output.log"

var startup := true

var highscore_path := "user://highscores.sav"

var config_dir := "user://config"
var replay_dir := "user://replays"

var game_mode: int = GameMode.FREE :
	set(mode):
		if mode < GameMode.size():
			if mode == game_mode:
				return
			game_mode = mode
			game_mode_changed.emit(game_mode)
var active_track: Track = null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("race_mode"):
		if game_mode == GameMode.FREE:
			self.game_mode = GameMode.RACE
		elif game_mode == GameMode.RACE:
			self.game_mode = GameMode.FREE


func initialize() -> void:
	var dir := DirAccess.open("user://")
	if not dir.dir_exists(config_dir):
		var _discard = dir.make_dir(config_dir)
	if not dir.dir_exists(replay_dir):
		var _discard = dir.make_dir(replay_dir)
	if not dir.file_exists(highscore_path):
		var _file := FileAccess.open(highscore_path, FileAccess.WRITE)

	startup = false


func get_formatted_date_time() -> String:
	var date_time := Time.get_datetime_dict_from_system()
	var time := "[%04d-%02d-%02d %02d:%02d:%02d]" % [date_time["year"], date_time["month"], \
			date_time["day"], date_time["hour"], date_time["minute"], date_time["second"]]
	return time


func show_error_popup(control: Node, error: String) -> void:
	await get_tree().process_frame
	var controller_dialog := AcceptDialog.new()
	controller_dialog.dialog_text = error
	control.add_child(controller_dialog)
	controller_dialog.popup_centered.call_deferred()


func log_error(err_code: int, message: String = "") -> void:
	var file := FileAccess.open(log_path, FileAccess.WRITE_READ)
	file.store_line("%s ERROR %d: %s" % [get_formatted_date_time(), err_code, message])
	file = null
