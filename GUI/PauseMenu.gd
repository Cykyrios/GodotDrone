class_name PauseMenu
extends Control


signal resumed
signal menu

var packed_quad_settings_menu := preload("res://GUI/QuadSettingsMenu.tscn")
var packed_help_page := preload("res://GUI/HelpPage.tscn")
var packed_options_menu := preload("res://GUI/options_menu/OptionsMenu.tscn")

var can_resume := true

@onready var button_resume := %ButtonResume as Button
@onready var button_quad := %ButtonQuad as Button
@onready var button_help := %ButtonHelp as Button
@onready var button_options := %ButtonOptions as Button
@onready var button_main_menu := %ButtonMainMenu as Button
@onready var pausemenu_container: PanelContainer = $PanelContainer


func _ready() -> void:
	var _discard = button_resume.pressed.connect(_on_resume_pressed)
	_discard = button_quad.pressed.connect(_on_quad_settings_pressed)
	_discard = button_help.pressed.connect(_on_help_pressed)
	_discard = button_options.pressed.connect(_on_options_pressed)
	_discard = button_main_menu.pressed.connect(_on_menu_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action("pause_menu") and event.is_pressed() and not event.is_echo():
		if get_tree().paused:
			unpause_game()
	elif event is InputEventKey and event.is_pressed() and event.keycode == KEY_F2:
		if get_tree().paused:
			toggle_menu_visibility()


func set_menu_visibility(show_menu: bool) -> void:
	visible = show_menu
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func toggle_menu_visibility() -> void:
	set_menu_visibility(not visible)


func _on_resume_pressed() -> void:
	unpause_game()


func _on_quad_settings_pressed() -> void:
	if packed_quad_settings_menu.can_instantiate():
		var quad_settings_menu := packed_quad_settings_menu.instantiate()
		add_child(quad_settings_menu)
		can_resume = false
		pausemenu_container.visible = false
		await quad_settings_menu.back
		quad_settings_menu.queue_free()
		pausemenu_container.visible = true
		can_resume = true


func _on_help_pressed() -> void:
	if packed_help_page.can_instantiate():
		var help_page := packed_help_page.instantiate()
		add_child(help_page)
		can_resume = false
		pausemenu_container.visible = false
		await help_page.back
		help_page.queue_free()
		pausemenu_container.visible = true
		can_resume = true


func _on_options_pressed() -> void:
	if packed_options_menu.can_instantiate():
		var options_menu := packed_options_menu.instantiate()
		add_child(options_menu)
		can_resume = false
		pausemenu_container.visible = false
		await options_menu.back
		options_menu.queue_free()
		pausemenu_container.visible = true
		can_resume = true


func _on_menu_pressed() -> void:
	can_resume = false
	var confirm_dialog := ConfirmationDialog.new()
	add_child(confirm_dialog)
	confirm_dialog.dialog_text = "Return to Main Menu?"
	confirm_dialog.ok_button_text = "Confirm"
	confirm_dialog.cancel_button_text = "Cancel"
	var _discard = confirm_dialog.confirmed.connect(func():
		can_resume = true
		resumed.emit()
		menu.emit())
	_discard = confirm_dialog.canceled.connect(func(): can_resume = true)
	confirm_dialog.popup_centered()


func unpause_game() -> void:
	set_menu_visibility(false)
	resumed.emit()
