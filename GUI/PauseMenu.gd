extends Control


var packed_quad_settings_menu := preload("res://GUI/QuadSettingsMenu.tscn")
var packed_help_page := preload("res://GUI/HelpPage.tscn")
var packed_options_menu := preload("res://GUI/OptionsMenu.tscn")

var can_resume := true

signal resumed
signal menu


func _ready() -> void:
	var _discard = $PanelContainer/VBoxContainer/ButtonResume.pressed.connect(_on_resume_pressed)
	_discard = $PanelContainer/VBoxContainer/ButtonQuad.pressed.connect(_on_quad_settings_pressed)
	_discard = $PanelContainer/VBoxContainer/ButtonHelp.pressed.connect(_on_help_pressed)
	_discard = $PanelContainer/VBoxContainer/ButtonOptions.pressed.connect(_on_options_pressed)
	_discard = $PanelContainer/VBoxContainer/ButtonMainMenu.pressed.connect(_on_menu_pressed)


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
		get_parent().add_child(quad_settings_menu)
		can_resume = false
		visible = false
		await quad_settings_menu.back
		quad_settings_menu.queue_free()
		visible = true
		can_resume = true


func _on_help_pressed() -> void:
	if packed_help_page.can_instantiate():
		var help_page := packed_help_page.instantiate()
		get_parent().add_child(help_page)
		can_resume = false
		visible = false
		await help_page.back
		help_page.queue_free()
		visible = true
		can_resume = true


func _on_options_pressed() -> void:
	if packed_options_menu.can_instantiate():
		var options_menu := packed_options_menu.instantiate()
		get_parent().add_child(options_menu)
		can_resume = false
		visible = false
		await options_menu.back
		options_menu.queue_free()
		visible = true
		can_resume = true


func _on_menu_pressed() -> void:
	var confirm_dialog: Popup = load("res://GUI/ConfirmationPopup.tscn").instantiate()
	can_resume = false
	add_child(confirm_dialog)
	confirm_dialog.set_text("Return to Main Menu?")
	confirm_dialog.set_yes_button("Confirm")
	confirm_dialog.set_no_button("Cancel")
	confirm_dialog.remove_alt_button()
	confirm_dialog.visible = true
	var dialog: int = await confirm_dialog.validated
	if dialog == 0:
		can_resume = true
		resumed.emit()
		menu.emit()
		return
	else:
		confirm_dialog.queue_free()
	can_resume = true


func unpause_game() -> void:
	set_menu_visibility(false)
	resumed.emit()
