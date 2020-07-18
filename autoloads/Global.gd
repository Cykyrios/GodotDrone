extends Node


signal game_mode_changed


enum GameMode {FREE, RACE}


var log_path := "user://output.log"

var startup := true

var game_mode: int = GameMode.FREE setget set_game_mode
var active_track: Track = null


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("race_mode"):
		if game_mode == GameMode.FREE:
			self.game_mode = GameMode.RACE
		elif game_mode == GameMode.RACE:
			self.game_mode = GameMode.FREE


func get_formatted_date_time() -> String:
	var date_time := OS.get_datetime()
	var time := "[%04d-%02d-%02d %02d:%02d:%02d]" % [date_time["year"], date_time["month"], \
			date_time["day"], date_time["hour"], date_time["minute"], date_time["second"]]
	return time


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
