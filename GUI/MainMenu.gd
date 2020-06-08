extends Control


var packed_quad_settings_menu = preload("res://GUI/QuadSettingsMenu.tscn")
var packed_options_menu = preload("res://GUI/OptionsMenu.tscn")
var packed_popup = preload("res://GUI/ConfirmationPopup.tscn")

var level = preload("res://sceneries/Level1.tscn")


func _ready():
	$PanelContainer/VBoxContainer/ButtonFly.connect("pressed", self, "_on_fly_pressed")
	$PanelContainer/VBoxContainer/ButtonQuad.connect("pressed", self, "_on_quad_settings_pressed")
	$PanelContainer/VBoxContainer/ButtonOptions.connect("pressed", self, "_on_options_pressed")
	$PanelContainer/VBoxContainer/ButtonQuit.connect("pressed", self, "_on_quit_pressed")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Global.startup:
		Global.startup = false
		var error = Global.load_input_map(true)
		if error:
			var controller_dialog = packed_popup.instance()
			add_child(controller_dialog)
			controller_dialog.set_text(error)
			controller_dialog.set_buttons("OK")
			controller_dialog.show_modal(true)
			var dialog = yield(controller_dialog, "validated")


func _on_fly_pressed():
	get_tree().change_scene_to(level)


func _on_quad_settings_pressed():
	if packed_quad_settings_menu.can_instance():
		var quad_settings_menu = packed_quad_settings_menu.instance()
		get_parent().add_child(quad_settings_menu)
		visible = false
		yield(quad_settings_menu, "back")
		quad_settings_menu.queue_free()
		visible = true


func _on_options_pressed():
	if packed_options_menu.can_instance():
		var options_menu = packed_options_menu.instance()
		get_parent().add_child(options_menu)
		visible = false
		yield(options_menu, "back")
		options_menu.queue_free()
		visible = true


func _on_quit_pressed():
	var confirm_dialog = packed_popup.instance()
	add_child(confirm_dialog)
	confirm_dialog.set_text("Do you really want to quit?")
	confirm_dialog.set_buttons("Quit", "Cancel")
	confirm_dialog.show_modal(true)
	var dialog = yield(confirm_dialog, "validated")
	if dialog == 0:
		get_tree().quit()
