extends Control


var packed_quad_settings_menu := preload("res://GUI/QuadSettingsMenu.tscn")
var packed_help_page := preload("res://GUI/HelpPage.tscn")
var packed_options_menu := preload("res://GUI/OptionsMenu.tscn")

var can_resume := true
var show_menu := true

signal resumed
signal menu


func _ready() -> void:
	var _discard = $PanelContainer/VBoxContainer/ButtonResume.connect("pressed", self, "_on_resume_pressed")
	_discard = $PanelContainer/VBoxContainer/ButtonQuad.connect("pressed", self, "_on_quad_settings_pressed")
	_discard = $PanelContainer/VBoxContainer/ButtonHelp.connect("pressed", self, "_on_help_pressed")
	_discard = $PanelContainer/VBoxContainer/ButtonOptions.connect("pressed", self, "_on_options_pressed")
	_discard = $PanelContainer/VBoxContainer/ButtonMainMenu.connect("pressed", self, "_on_menu_pressed")


func _input(event: InputEvent) -> void:
	if event.is_action("pause_menu") and event.is_pressed() and not event.is_echo():
		if get_tree().paused:
			set_menu_visibility(true)
	elif event is InputEventKey and event.is_pressed() and event.scancode == KEY_F2:
		if get_tree().paused:
			toggle_menu_visibility()


func set_menu_visibility(show: bool) -> void:
	show_menu = show
	visible = show_menu
	if show_menu:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func toggle_menu_visibility() -> void:
	set_menu_visibility(not show_menu)


func _on_resume_pressed() -> void:
	set_menu_visibility(true)
	emit_signal("resumed")


func _on_quad_settings_pressed() -> void:
	if packed_quad_settings_menu.can_instance():
		var quad_settings_menu := packed_quad_settings_menu.instance()
		get_parent().add_child(quad_settings_menu)
		visible = false
		yield(quad_settings_menu, "back")
		quad_settings_menu.queue_free()
		visible = true


func _on_help_pressed() -> void:
	if packed_help_page.can_instance():
		var help_page := packed_help_page.instance()
		get_parent().add_child(help_page)
		visible = false
		yield(help_page, "back")
		help_page.queue_free()
		visible = true


func _on_options_pressed() -> void:
	if packed_options_menu.can_instance():
		var options_menu := packed_options_menu.instance()
		get_parent().add_child(options_menu)
		can_resume = false
		visible = false
		yield(options_menu, "back")
		options_menu.queue_free()
		visible = true
		can_resume = true


func _on_menu_pressed() -> void:
	var confirm_dialog: Control = load("res://GUI/ConfirmationPopup.tscn").instance()
	can_resume = false
	add_child(confirm_dialog)
	confirm_dialog.set_text("Return to Main Menu?")
	confirm_dialog.set_yes_button("Confirm")
	confirm_dialog.set_no_button("Cancel")
	confirm_dialog.remove_alt_button()
	confirm_dialog.show_modal(true)
	var dialog: int = yield(confirm_dialog, "validated")
	if dialog == 0:
		can_resume = true
		emit_signal("resumed")
		emit_signal("menu")
		return
	else:
		confirm_dialog.queue_free()
	can_resume = true
