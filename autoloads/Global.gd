extends Node


signal game_mode_changed


enum GameMode {FREE, RACE}
enum RaceState {START, RACE, END}


var packed_popup := preload("res://GUI/ConfirmationPopup.tscn")

var log_path := "user://output.log"

var startup := true

var highscore_path := "user://highscores.sav"

var config_dir := "user://config"
var replay_dir := "user://replays"

var game_mode: int = GameMode.FREE setget set_game_mode
var active_track: Track = null


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("race_mode"):
		if game_mode == GameMode.FREE:
			self.game_mode = GameMode.RACE
		elif game_mode == GameMode.RACE:
			self.game_mode = GameMode.FREE


func initialize() -> void:
	var dir := Directory.new()
	if not dir.dir_exists(config_dir):
		dir.make_dir(config_dir)
	if not dir.dir_exists(replay_dir):
		dir.make_dir(replay_dir)
	if not dir.file_exists(highscore_path):
		var file := File.new()
		var _discard = file.open(highscore_path, File.WRITE)
		file.close()
	
	startup = false


func get_formatted_date_time() -> String:
	var date_time := OS.get_datetime()
	var time := "[%04d-%02d-%02d %02d:%02d:%02d]" % [date_time["year"], date_time["month"], \
			date_time["day"], date_time["hour"], date_time["minute"], date_time["second"]]
	return time


func show_error_popup(control: Control, error: String) -> void:
	var controller_dialog := packed_popup.instance()
	control.add_child(controller_dialog)
	controller_dialog.set_text(error)
	controller_dialog.set_buttons("OK")
	controller_dialog.show_modal(true)
	var _dialog = yield(controller_dialog, "validated")


func log_error(err_code: int, message: String = "") -> void:
	var file := File.new()
	var _discard = file.open(log_path, File.WRITE_READ)
	file.store_line("%s ERROR %d: %s" % [get_formatted_date_time(), err_code, message])
	file.close()


func set_game_mode(mode: int) -> void:
	if mode < GameMode.size():
		if mode == game_mode:
			return
		game_mode = mode
		emit_signal("game_mode_changed", game_mode)
