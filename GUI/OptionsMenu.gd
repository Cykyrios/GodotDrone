extends Control


var packed_game_settings_menu := preload("res://GUI/GameSettingsMenu.tscn")
var packed_graphics_menu := preload("res://GUI/GraphicsMenu.tscn")
var packed_audio_menu := preload("res://GUI/AudioMenu.tscn")
var packed_controls_menu := preload("res://GUI/ControlsMenu.tscn")

signal back


onready var button_game := $PanelContainer/VBoxContainer/ButtonGame
onready var button_graphics := $PanelContainer/VBoxContainer/ButtonGraphics
onready var button_audio := $PanelContainer/VBoxContainer/ButtonAudio
onready var button_controls := $PanelContainer/VBoxContainer/ButtonControls


func _ready() -> void:
	var _discard = button_game.connect("pressed", self, "_on_game_settings_pressed")
	_discard = button_graphics.connect("pressed", self, "_on_graphics_pressed")
	_discard = button_audio.connect("pressed", self, "_on_audio_pressed")
	_discard = button_controls.connect("pressed", self, "_on_controls_pressed")
	_discard = $PanelContainer/VBoxContainer/ButtonBack.connect("pressed", self, "_on_back_pressed")


func _input(event):
	if event.is_action("ui_cancel") and event.is_pressed() and not event.is_echo():
		accept_event()
		emit_signal("back")


func _on_game_settings_pressed() -> void:
	if packed_game_settings_menu.can_instance():
		var game_settings_menu := packed_game_settings_menu.instance()
		get_parent().add_child(game_settings_menu)
		visible = false
		yield(game_settings_menu, "back")
		game_settings_menu.queue_free()
		visible = true


func _on_graphics_pressed() -> void:
	if packed_graphics_menu.can_instance():
		var graphics_menu := packed_graphics_menu.instance()
		get_parent().add_child(graphics_menu)
		visible = false
		yield(graphics_menu, "back")
		graphics_menu.queue_free()
		visible = true


func _on_audio_pressed() -> void:
	if packed_audio_menu.can_instance():
		var audio_menu := packed_audio_menu.instance()
		get_parent().add_child(audio_menu)
		visible = false
		yield(audio_menu, "back")
		audio_menu.queue_free()
		visible = true


func _on_controls_pressed() -> void:
	if packed_controls_menu.can_instance():
		var controls_menu := packed_controls_menu.instance()
		get_parent().add_child(controls_menu)
		visible = false
		yield(controls_menu, "back")
		controls_menu.queue_free()
		visible = true


func _on_back_pressed() -> void:
	emit_signal("back")
