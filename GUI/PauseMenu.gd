extends Control


var packed_options_menu = preload("res://GUI/OptionsMenu.tscn")

var can_resume = true

signal resumed
signal menu


func _ready():
	$PanelContainer/VBoxContainer/ButtonResume.connect("pressed", self, "_on_resume_pressed")
	$PanelContainer/VBoxContainer/ButtonOptions.connect("pressed", self, "_on_options_pressed")
	$PanelContainer/VBoxContainer/ButtonMainMenu.connect("pressed", self, "_on_menu_pressed")


func _on_resume_pressed():
	emit_signal("resumed")


func _on_options_pressed():
	if packed_options_menu.can_instance():
		var options_menu = packed_options_menu.instance()
		get_parent().add_child(options_menu)
		can_resume = false
		visible = false
		yield(options_menu, "back")
		options_menu.queue_free()
		visible = true
		can_resume = true


func _on_menu_pressed():
	var confirm_dialog = load("res://GUI/ConfirmationPopup.tscn").instance()
	can_resume = false
	add_child(confirm_dialog)
	confirm_dialog.set_text("Return to Main Menu?")
	confirm_dialog.set_yes_button("Confirm")
	confirm_dialog.set_no_button("Cancel")
	confirm_dialog.remove_alt_button()
	confirm_dialog.show_modal(true)
	var dialog = yield(confirm_dialog, "validated")
	if dialog == 0:
		can_resume = true
		emit_signal("resumed")
		emit_signal("menu")
		return
	else:
		confirm_dialog.queue_free()
	can_resume = true
