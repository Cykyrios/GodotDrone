extends Control


var packed_game_settings_menu = preload("res://GUI/GameSettingsMenu.tscn")
var packed_controls_menu = preload("res://GUI/ControlsMenu.tscn")

signal back


func _ready():
	var _discard = $PanelContainer/VBoxContainer/ButtonGame.connect("pressed", self, "_on_game_settings_pressed")
	_discard = $PanelContainer/VBoxContainer/ButtonControls.connect("pressed", self, "_on_controls_pressed")
	_discard = $PanelContainer/VBoxContainer/ButtonBack.connect("pressed", self, "_on_back_pressed")


func _on_game_settings_pressed():
	if packed_game_settings_menu.can_instance():
		var game_settings_menu = packed_game_settings_menu.instance()
		get_parent().add_child(game_settings_menu)
		visible = false
		yield(game_settings_menu, "back")
		game_settings_menu.queue_free()
		visible = true


func _on_controls_pressed():
	if packed_controls_menu.can_instance():
		var controls_menu = packed_controls_menu.instance()
		get_parent().add_child(controls_menu)
		visible = false
		yield(controls_menu, "back")
		controls_menu.queue_free()
		visible = true


func _on_back_pressed():
	emit_signal("back")
