extends Control


var packed_quad_settings_menu := preload("res://GUI/QuadSettingsMenu.tscn")
var packed_options_menu := preload("res://GUI/OptionsMenu.tscn")
var packed_help_page := preload("res://GUI/HelpPage.tscn")
var packed_popup := preload("res://GUI/ConfirmationPopup.tscn")


func _ready() -> void:
	var _discard = $PanelContainer/VBoxContainer/ButtonFly.pressed.connect(_on_fly_pressed)
	_discard = $PanelContainer/VBoxContainer/ButtonQuad.pressed.connect(_on_quad_settings_pressed)
	_discard = $PanelContainer/VBoxContainer/ButtonHelp.pressed.connect(_on_help_pressed)
	_discard = $PanelContainer/VBoxContainer/ButtonOptions.pressed.connect(_on_options_pressed)
	_discard = $PanelContainer/VBoxContainer/ButtonQuit.pressed.connect(_on_quit_pressed)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if Global.startup:
		Global.initialize()
		var error := Graphics.load_graphics_settings()
		if error:
			Global.show_error_popup(self, error)
		error = Audio.load_audio_settings()
		if error:
			Global.show_error_popup(self, error)
		error = Controls.load_input_map(true)
		if error:
			Global.show_error_popup(self, error)


func _on_fly_pressed() -> void:
	var _discard = get_tree().change_scene_to_file("res://sceneries/Level1.tscn")


func _on_quad_settings_pressed() -> void:
	if packed_quad_settings_menu.can_instantiate():
		var quad_settings_menu := packed_quad_settings_menu.instantiate()
		get_parent().add_child(quad_settings_menu)
		visible = false
		await quad_settings_menu.back
		quad_settings_menu.queue_free()
		visible = true


func _on_help_pressed() -> void:
	if packed_help_page.can_instantiate():
		var help_page := packed_help_page.instantiate()
		get_parent().add_child(help_page)
		visible = false
		await help_page.back
		help_page.queue_free()
		visible = true


func _on_options_pressed() -> void:
	if packed_options_menu.can_instantiate():
		var options_menu := packed_options_menu.instantiate()
		get_parent().add_child(options_menu)
		visible = false
		await options_menu.back
		options_menu.queue_free()
		visible = true


func _on_quit_pressed() -> void:
	var confirm_dialog := packed_popup.instantiate()
	add_child(confirm_dialog)
	confirm_dialog.set_text("Do you really want to quit?")
	confirm_dialog.set_buttons("Quit", "Cancel")
#	confirm_dialog.show_modal(true)
	confirm_dialog.visible = true
	var dialog: int = await confirm_dialog.validated
	if dialog == 0:
		get_tree().quit()
