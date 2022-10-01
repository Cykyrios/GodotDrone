extends Control


signal back

var packed_game_settings_menu := preload("res://GUI/GameSettingsMenu.tscn")
var packed_graphics_menu := preload("res://GUI/GraphicsMenu.tscn")
var packed_audio_menu := preload("res://GUI/AudioMenu.tscn")
var packed_controls_menu := preload("res://GUI/ControlsMenu.tscn")


@onready var button_game := $PanelContainer/VBoxContainer/ButtonGame
@onready var button_graphics := $PanelContainer/VBoxContainer/ButtonGraphics
@onready var button_audio := $PanelContainer/VBoxContainer/ButtonAudio
@onready var button_controls := $PanelContainer/VBoxContainer/ButtonControls


func _ready() -> void:
	var _discard = button_game.pressed.connect(_on_game_settings_pressed)
	_discard = button_graphics.pressed.connect(_on_graphics_pressed)
	_discard = button_audio.pressed.connect(_on_audio_pressed)
	_discard = button_controls.pressed.connect(_on_controls_pressed)
	_discard = $PanelContainer/VBoxContainer/ButtonBack.pressed.connect(_on_back_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action("ui_cancel") and event.is_pressed() and not event.is_echo():
		accept_event()
		back.emit()


func _on_game_settings_pressed() -> void:
	if packed_game_settings_menu.can_instantiate():
		var game_settings_menu := packed_game_settings_menu.instantiate()
		get_parent().add_child(game_settings_menu)
		visible = false
		await game_settings_menu.back
		game_settings_menu.queue_free()
		visible = true


func _on_graphics_pressed() -> void:
	if packed_graphics_menu.can_instantiate():
		var graphics_menu := packed_graphics_menu.instantiate()
		get_parent().add_child(graphics_menu)
		visible = false
		await graphics_menu.back
		graphics_menu.queue_free()
		visible = true


func _on_audio_pressed() -> void:
	if packed_audio_menu.can_instantiate():
		var audio_menu := packed_audio_menu.instantiate()
		get_parent().add_child(audio_menu)
		visible = false
		await audio_menu.back
		audio_menu.queue_free()
		visible = true


func _on_controls_pressed() -> void:
	if packed_controls_menu.can_instantiate():
		var controls_menu := packed_controls_menu.instantiate()
		get_parent().add_child(controls_menu)
		visible = false
		await controls_menu.back
		controls_menu.queue_free()
		visible = true


func _on_back_pressed() -> void:
	back.emit()
